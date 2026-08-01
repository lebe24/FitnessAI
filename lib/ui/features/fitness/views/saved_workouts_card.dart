import 'dart:io';

import 'package:fitness/l10n/generated/app_localizations.dart';
import 'package:fitness/ui/features/fitness/view_models/fitness_view_model.dart';
import 'package:fitness/ui/features/fitness/views/saved_program.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

const _kCard   = Color(0xFF111318);
const _kBorder = Color(0xFF1E2330);
const _kDim    = Color(0x80FFFFFF);

/// Entry point to the user's saved workout programs — shows the most recent
/// plan's image and opens [SavedProgramPage] on tap.
///
/// Requires a [FitnessViewModel] above it in the tree.
class SavedWorkoutsCard extends StatelessWidget {
  const SavedWorkoutsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    // watch, not read: the card must repaint once plans finish loading,
    // otherwise it can sit on a stale empty state.
    final fitnessVm = context.watch<FitnessViewModel>();
    final savedPath =
        fitnessVm.plans.isNotEmpty ? fitnessVm.plans.first.imagePath : null;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: fitnessVm,
            child: const SavedProgramPage(),
          ),
        ),
      ),
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // image panel
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(20)),
              child: SizedBox(
                width: 110,
                height: double.infinity,
                child: savedPath != null
                    ? FutureBuilder<bool>(
                        future: File(savedPath).exists(),
                        builder: (_, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const _ImagePlaceholder();
                          }
                          return snap.data == true
                              ? Image.file(File(savedPath),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const _ImagePlaceholder())
                              : const _ImagePlaceholder();
                        },
                      )
                    : const _ImagePlaceholder(),
              ),
            ),
            // text + cta
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      t.savedWorkoutsTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.savedWorkoutsSubtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        height: 1.4,
                        color: _kDim,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.folder_open_rounded,
                              color: Colors.white.withValues(alpha: 0.6),
                              size: 13),
                          const SizedBox(width: 5),
                          Text(
                            t.viewAllAction,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.white.withValues(alpha: 0.05),
        child: Center(
          child: Icon(
            Icons.folder_copy_outlined,
            color: Colors.white.withValues(alpha: 0.2),
            size: 36,
          ),
        ),
      );
}
