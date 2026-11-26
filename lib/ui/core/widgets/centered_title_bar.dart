import 'package:fitness/ui/features/analytic/views/body/body_ui.dart';
import 'package:flutter/material.dart';

/// The header the newer screens share: a round back button on the left and the
/// title centred over the whole width.
class CenteredTitleBar extends StatelessWidget {
  final String title;

  const CenteredTitleBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: SizedBox(
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Semantics(
                button: true,
                label: 'Back',
                child: GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: kBodyCard,
                      shape: BoxShape.circle,
                      border: Border.all(color: kBodyBorder),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: Colors.white),
                  ),
                ),
              ),
            ),
            // Kept clear of the button on both sides so a long title ellipsises
            // instead of sliding under it.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 52),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: bodyHeading(17),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
