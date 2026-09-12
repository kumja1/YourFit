import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_mistralai/langchain_mistralai.dart';
import 'package:langchain_google/langchain_google.dart';
import 'package:yourfit/src/models/index.dart';
import 'package:yourfit/src/utils/functions/init_services.dart';
import 'package:yourfit/src/utils/index.dart';
import 'package:yourfit/src/utils/objects/constants/env/env.dart';
import 'package:yourfit/src/utils/objects/constants/exercise/response_schema.dart';
import 'package:yourfit/src/utils/objects/supabase/supabase_vectorstore.dart';
import 'device_service.dart';

class ExerciseService {
  final DeviceService deviceService = Get.find<DeviceService>();
  late final Runnable runnable;

  void init() {
    Tool runningDestTool = Tool.fromFunction(
      name: "Running Destination Tool",
      description: "Tool for finding a suitable destination for running",
      inputJsonSchema: const {
        "type": "object",
        "properties": {
          "empty": {"type": "string"},
        },
      },
      func: (_) async {
        List<Position> nearbyPositions = await deviceService
            .getPositionsNearDevice();
        Position devicePos = await deviceService.getDevicePosition();

        return {
          "user_location": devicePos.toJson(),
          "nearby_locations": nearbyPositions.map(
            (p) => {
              ...p.toJson(),
              "distance_from_user": Geolocator.distanceBetween(
                devicePos.latitude,
                devicePos.longitude,
                p.latitude,
                p.longitude,
              ),
            },
          ),
        };
      },
    );
final model = ChatMistralAI(defaultOptions: ChatMistralAIOptions(

  safePrompt: true
));


    final agent = ToolsAgent.fromLLMAndTools(
      tools: [runningDestTool],
      llm: ChatMistralAI(apiKey: "UDbXGBX0J1W6rKQxQD1UUdPolK9F69H4",
      defaultOptions: ChatMistralAIOptions(
        model: "ministral-14b-2512"
      )),
      // llm: ChatGoogleGenerativeAI(
      //   apiKey: Env.geminiKey,
      //   defaultOptions: const ChatGoogleGenerativeAIOptions(
      //     model: "gemini-2.5-flash",
      //     responseMimeType: "application/json",
      //     safetySettings: [
      //       ChatGoogleGenerativeAISafetySetting(
      //         category:
      //             ChatGoogleGenerativeAISafetySettingCategory.sexuallyExplicit,
      //         threshold:
      //             ChatGoogleGenerativeAISafetySettingThreshold.blockLowAndAbove,
      //       ),
      //       ChatGoogleGenerativeAISafetySetting(
      //         category: ChatGoogleGenerativeAISafetySettingCategory.hateSpeech,
      //         threshold:
      //             ChatGoogleGenerativeAISafetySettingThreshold.blockLowAndAbove,
      //       ),
      //       ChatGoogleGenerativeAISafetySetting(
      //         category:
      //             ChatGoogleGenerativeAISafetySettingCategory.dangerousContent,
      //         threshold:
      //             ChatGoogleGenerativeAISafetySettingThreshold.blockLowAndAbove,
      //       ),
      //     ],
      //   ),
      // ),
      systemChatMessage: SystemChatMessagePromptTemplate.fromTemplate("""
    ---- Instructions ----
        You are a extremely considerate, cautious, medically accurate fitness trainer.
        Your task: Provide the user with an appropriate response to the prompt, always taking into consideration the parameters provided and their priority.
        Follow these rules:
        1. Response should be based on the given information as well as any additional information found in the dataset.
        2. Response should not contain anything redundant but remain relatively consistent with the historical data provided, increasing the difficulty if appropriate.
        3. Response should be in a JSON format and follow the schema provided.

        ---- Context ----
        {context}
        """),
      extraPromptMessages: [
        ChatMessagePromptTemplate.human("""
        Below is the information you will take into consideration when formulating your response.

        ---- Information ----
        {params}
        """),
        ChatMessagePromptTemplate.human("User Prompt: {prompt}"),
      ],
    );

    final vectorStore = Supabase(
      tableName: "documents",
      supabaseUrl: Env.supabaseUrl,
      supabaseKey: Env.supabaseKey,
      embeddings: GoogleGenerativeAIEmbeddings(
        model: "gemini-embedding-001",
        apiKey: Env.geminiKey,
        dimensions: 1024,
      ),
    );

    runnable =
        Runnable.fromMap({
          "context":
              Runnable.getItemFromMap("prompt") |
              (vectorStore.asRetriever(
                    defaultOptions: VectorStoreRetrieverOptions(
                      searchType: VectorStoreMMRSearch(k: 20),
                    ),
                  ) |
                  Runnable.mapInput((docs) => docs.join("\n"))),
          "prompt": Runnable.getItemFromMap("prompt"),
          "params":
              Runnable.getItemFromMap("params") |
              Runnable.mapInput((params) {
                int i = 0;
                StringBuffer buffer = StringBuffer();
                for (MapEntry<String, Parameter> entry
                    in (params as Map<String, Parameter>).entries) {
                  buffer.writeln(
                    "${entry.key}: ${entry.value.value} (priority: ${entry.value.priority?.name ?? Priority.low}) (description: ${entry.value.description})",
                  );
                }
                logger.info("Mapped parameters: $buffer");
                return buffer.toString();
              }),
        }) |
        AgentExecutor(
          agent: agent,
          maxExecutionTime: Duration(minutes: 1),
          handleParsingErrors: (e) {
            logger.severe("Error in AgentExecutor", e);
            return {};
          },
        ) |
        ToolsAgentOutputParser();
  }

  Future<Map<String, dynamic>> invoke(
    String prompt,
    Map<String, Parameter> params, {
    Map<String, dynamic>? responseSchema,
  }) async {
    logger.info("Invoking LLM with parameters: $params");
    try {
      Map<String, dynamic> results =
          await runnable.invoke(
                {"params": params, "prompt": prompt},
                options: responseSchema == null
                    ? null
                    : ChatGoogleGenerativeAIOptions(
                        responseSchema: responseSchema,
                      ),
              )
              as Map<String, dynamic>;

      logger.info("Results: $results");
      return results;
    } on Error catch (e) {
      logger.severe("Error in invoke", e);
      return {};
    }
  }

  Future<Map<String, dynamic>> invokeWithUser(
    UserData? user,
    String prompt, {
    Map<String, dynamic>? responseSchema,
    Map<String, Parameter> additionalParams = const {},
  }) async {
    try {
      if (user == null) return {};

      return await invoke(prompt, {
        "age": Parameter(
          priority: Priority.critical,
          value: user.age,
          description: "User's age in years",
        ),
          "disabilities": Parameter(
          priority: Priority.critical,
          value: user.disabilities,
          description: "User's physical limitations or disabilities (extreme caution is required )",
        ),
        "bmi": Parameter(
          priority: Priority.critical,
          value: user.bmi,
          description: "User's body mass index",
        ),
        "goal": Parameter(
          priority: Priority.high,
          value: user.goal,
          description: "User's fitness goal",
        ),
        "physicalFitness": Parameter(
          priority: Priority.high,
          value: user.physicalFitness,
          description: "User's current physical fitness level",
        ),
        "height": Parameter(
          priority: Priority.high,
          value: user.height,
          description: "User's height in centimeters (cm)",
        ),
        "weight": Parameter(
          priority: Priority.high,
          value: user.weight,
          description: "User's weight in pounds (lbs)",
        ),
        "gender": Parameter(
          priority: Priority.moderate,
          value: user.gender,
          description: "User's gender",
        ),
        "equipment": Parameter(
          priority: Priority.moderate,
          value: user.equipment,
          description: "Available equipment for workout",
        ),
        "workoutData": Parameter(
          priority: Priority.low,
          value: user.workoutData,
          description: "User's historical workout data",
        ),
        ...additionalParams,
      }, responseSchema: responseSchema);
    } on Error catch (e) {
      logger.severe("Error in invokeWithUser", e);
      return {};
    }
  }

  Future<WorkoutData?> getExercises(
    UserData? user, {
    String? prompt,
    ExerciseType? type,
    WorkoutFocus? focus,
    ExerciseDifficulty? difficulty,
    ExerciseIntensity? intensity,
    int count = 0,
    Map<String, Parameter> additionalParams = const {},
  }) async {
    try {
      final result = await invokeWithUser(
        user,
        "Provide the user with a workout. Ensure that each exercise follows the SRP (Single Responsibility Principle). ${prompt ?? ''}",
        additionalParams: {
          ...additionalParams,
          "workout_exercise_count": Parameter(
            priority: Priority.moderate,
            value: count,
            description:
                "Number of exercises in the workout. Provide a value if not provided",
          ),
          "workout_exercise_difficulty": Parameter(
            priority: Priority.low,
            value: difficulty?.name,
            description: "Desired difficulty level for workout exercises",
          ),
          "workout_exercise_intensity": Parameter(
            priority: Priority.low,
            value: intensity?.name,
            description: "Desired intensity level for workout exercises",
          ),
          "workout_exercise_type": Parameter(
            priority: Priority.moderate,
            value: type?.name,
            description: "Type of exercise (strength, cardio, etc.)",
          ),
          "workout_focus": Parameter(
            priority: Priority.moderate,
            value: focus?.name,
            description: "Desired focus for the overall workout.",
          ),
        },
        responseSchema: ResponseSchema.workout,
      );
      logger.info("[getExercises] Result $result");
      return result.isEmpty ? null : WorkoutData.fromMap(result);
    } on Error catch (e) {
      logger.severe("Error getting exercises", e);
      return null;
    }
  }
}


enum Priority {
  critical,
  high,
  moderate,
  low;
}

class Parameter {
  final Priority? priority;
  final String? description;
  final Object? value;

  const Parameter({this.priority, this.description, this.value});

  @override
  String toString() =>
      'Parameter(priority: $priority, description: $description, value: $value)';
}