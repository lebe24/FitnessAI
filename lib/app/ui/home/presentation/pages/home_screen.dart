import 'package:fitness/app/core/di.dart' as di;
import 'package:fitness/app/core/theme/app_pallet.dart';
import 'package:fitness/app/ui/activity/activity_page.dart';
import 'package:fitness/app/ui/fitness/presentation/page/fitness_page.dart';
import 'package:fitness/app/ui/fitness/presentation/bloc/fitness_bloc.dart';
import 'package:fitness/app/ui/home/presentation/widget/custom_bottomBar.dart';
import 'package:fitness/app/ui/profile/presentation/page/profile_page.dart';
import 'package:fitness/app/ui/analytic/statistics_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;

  List<Widget> get pages => <Widget>[
        BlocProvider(
          create: (context) => di.sl<FitnessBloc>(),
          child: const FitnessPage(),
        ),
        ActivityPage(),
        StatisticsPage(),
        ProfilePage(),
      ];


  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      backgroundColor: AppPalete.backgroundColorBk,
      
      body: Stack(
        children: [
          pages[currentIndex],
          Positioned(
            bottom: 0,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: CustomBottombar(
                      onItemTapped: (index) {
              setState(() {
                currentIndex = index;
              });
                      }, currentIndex: currentIndex,
                    ),
            ),
          ),
        ],
      ),
      // bottomNavigationBar: CustomBottombar(
      //   onItemTapped: (index) {
      //     setState(() {
      //       currentIndex = index;
      //     });
      //   }, currentIndex: currentIndex,
      // ),
    );
  }
}