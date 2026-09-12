import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yourfit/src/routing/router.gr.dart';

@RoutePage()
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AutoTabsScaffold(
      routes: const [RoadmapRoute(), ExerciseRoute(), ProfileRoute()],
      bottomNavigationBuilder: (_, tabsRouter) {
        return BottomNavigationBar(
          currentIndex: tabsRouter.activeIndex,
          onTap: tabsRouter.setActiveIndex,
          items: const [
            BottomNavigationBarItem(label: 'Roadmap', icon: Icon(Icons.map)),
            BottomNavigationBarItem(
              label: 'Workouts',
              icon: Icon(Icons.fitness_center),
            ),
            BottomNavigationBarItem(label: 'Profile', icon: Icon(Icons.person)),
          ],
        );
      },
    );
  }
}
