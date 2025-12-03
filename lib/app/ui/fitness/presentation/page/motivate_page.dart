import 'package:fitness/app/core/constant/assets.dart';
import 'package:flutter/material.dart';

class MotivatePage extends StatelessWidget {
  const MotivatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body:Stack(
        children: [
          SizedBox(
            height: double.infinity,
            child: Image.asset(
              ImagePath.unstoppable,
              fit: BoxFit.fill,
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.15,
            child: Positioned(
              top: 50,
              left: 20,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios, 
                        color: Colors.black,
                        size: 30,),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    IconButton(onPressed: (){}, 
                    icon: const Icon(
                      Icons.volume_up_rounded, 
                      color: Colors.black,
                      size: 30,)
                  )
                  ],
                ),
              ),
            ),
          ),
        ],
      )
    );
  }
}