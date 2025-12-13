import 'package:fitness/app/core/common/widget/appWidget.dart';
import 'package:fitness/app/ui/activity/activity_item_page.dart';
import 'package:flutter/material.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  final TextEditingController controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  
                  child: AppWidgets.appLogo()),
                Text(
                  ': ACTIVITY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 15.0,right: 15,top: 8.0),
            child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 20.0,
                      offset: Offset(0, 6.0)
                    )
                  ],
                  borderRadius: BorderRadius.circular(15.0),
                  color: Colors.white
                ),
                child: TextField(
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Search Activities'
                  ),
                ),),
          ),
          
          const SizedBox(height: 30),
          /// Icon Grid
          Expanded(
            child: _buildGridSection(),
          ),
        ],
      ),
    );
  }

  /// GRID SECTION
  Widget _buildGridSection() {
    final items = [
      _CategoryItem("Running", Icons.play_circle_fill, Colors.blueAccent, true),
      _CategoryItem("Stair climbing outdoors", Icons.campaign, Colors.teal, true),
      _CategoryItem("Backpacking", Icons.favorite, Colors.redAccent, false),
      _CategoryItem("Speed walking", Icons.videocam, Colors.purpleAccent, false),
      _CategoryItem("Hiking", Icons.camera_alt, Colors.blueGrey.shade300, false),
      _CategoryItem("Rock climbing", Icons.pie_chart, Colors.orange, false),
      _CategoryItem("Print products", Icons.print, Colors.blueAccent, false),
      _CategoryItem("Jump rope", Icons.description, Colors.teal, false),
      _CategoryItem("Canva Code", Icons.code, Colors.green, false),
      _CategoryItem("Website", Icons.web, Colors.indigo, false),
      _CategoryItem("Email", Icons.mail, Colors.deepPurple, true),
      _CategoryItem("Whiteboard", Icons.border_all, Colors.green, false),
    ];

    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 3,
      mainAxisSpacing: 4,
      crossAxisSpacing: 5,
      
      children: items.map((e) => _buildCategoryItem(e)).toList(),
    );
  }

  /// SINGLE CATEGORY ICON BOX
  Widget _buildCategoryItem(_CategoryItem item,) {
    return GestureDetector(
      onTap: (){
        Navigator.push(
              context,
              MaterialPageRoute(builder: (_) =>  ActivityItemPage(data: item.label,)),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 70,
                width: 70,
                decoration: BoxDecoration(
                  color: item.color,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: item.color.withOpacity(0.4),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Icon(item.icon, color: Colors.white, size: 34),
              ),
      
              if (item.isNew)
                Positioned(
                  right: -8,
                  top: -8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      "New",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
      
          const SizedBox(height: 10),
      
          Text(
            item.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          )
        ],
      ),
    );
  }

}

/// Helper models/widgets
class _CategoryItem {
  final String label;
  final IconData icon;
  final Color color;
  final bool isNew;

  _CategoryItem(this.label, this.icon, this.color, this.isNew);
}

