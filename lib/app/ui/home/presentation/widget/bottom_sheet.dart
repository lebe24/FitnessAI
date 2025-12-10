import 'dart:ui';
import 'package:fitness/app/core/common/widget/appWidget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

 Widget CupertinoModalBottomSheet({
  bool expand = true,
  required String text,
  required BuildContext context,
  Color backgroundColor = const Color(0x00000000),
}) {
  return BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
    child: Material(
      color: Colors.white,
      child: Scaffold(
        backgroundColor: backgroundColor,
        extendBodyBehindAppBar: true,
        appBar: appBar(context),
        body: CustomScrollView(
          physics: ClampingScrollPhysics(),
          slivers: <Widget>[
            SliverSafeArea(
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    Text(text,
                      style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 200,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Scrollable(
                          viewportBuilder: (BuildContext context, position) { 
                            return SingleChildScrollView(
                              child: Text("Nice — looks like you’re already putting in solid work 💪🏽. Based on your physique in the image, you seem to have a good base — your arms are toned and have definition, so the goal now is likely increasing muscle size (hypertrophy) in your biceps, triceps, and forearms.Here’s a 4-day arm-focused workout plan designed to build size and strength while keeping balance between pushing (triceps) and pulling (biceps) movements.",
                              style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.black87,
                              ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: Divider(thickness: 0.5),
                ),
            ),
            SliverToBoxAdapter(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text("🗓 Weekly Split",
                        style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 200,
                      child:ListView(
                        reverse: true,
                        scrollDirection: Axis.horizontal,
                        physics: PageScrollPhysics(),
                        padding: EdgeInsets.all(12).copyWith(
                            right: MediaQuery.of(context).size.width / 2 - 100),
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network('https://media.istockphoto.com/id/1035561592/vector/vector-design-element-for-the-fitness-center.jpg?s=612x612&w=0&k=20&c=k3yyyEcqeivby9iE7gZIk33PAjtDqNsdEdYiMjw7qsM='),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                clipBehavior: Clip.antiAlias,
                                children: [
                                  Image.network(
                                    'https://media.istockphoto.com/id/1035561592/vector/vector-design-element-for-the-fitness-center.jpg?s=612x612&w=0&k=20&c=k3yyyEcqeivby9iE7gZIk33PAjtDqNsdEdYiMjw7qsM='),
                                  Center(
                                    child: Text("20",
                                      style: GoogleFonts.poppins(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network('https://media.istockphoto.com/id/1035561592/vector/vector-design-element-for-the-fitness-center.jpg?s=612x612&w=0&k=20&c=k3yyyEcqeivby9iE7gZIk33PAjtDqNsdEdYiMjw7qsM='),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ),
            SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                      padding: const EdgeInsets.all(8.0),
                        child: Text("💥 GOAL: Bigger, Stronger Arms (8–12 Week Plan)",
                          style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                          ),
                        ),
                      ),
                      Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text("Focus: Hypertrophy\nEquipment: Dumbbells, Barbell, Cable Machine\nFrequency: 4 Days/Week",
                        style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.normal,
                            color: Colors.black87,
                        ),
                      ),
                    ),
                    ],
                  )
                ),
            ),
            SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                      padding: const EdgeInsets.all(8.0),
                        child: Text("🧠 Extra Notes",
                          style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                          ),
                        ),
                      ),
                      Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text("* Rest: 60–90 seconds between sets.\n* Progressive Overload: Aim to increase weights or reps each week.\n* Form: Prioritize proper form to prevent injury and maximize gains.\n* Nutrition: \b * Protein: 1.6–2.2g per kg of body weight daily.* Add a small calorie surplus (200–300 kcal/day) for growth.",
                        style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.normal,
                            color: Colors.black87,
                        ),
                      ),
                    ),
                    ],
                  )
                ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child:AppWidgets.roundbtnText(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  text: "Save Plan",
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

PreferredSizeWidget appBar(BuildContext context) {
  return AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(
        color: Colors.black87,
        Icons.close ,
        size: 28,
      ),
      onPressed: () {
        Navigator.of(context).pop();
      },
    ),
  );
}