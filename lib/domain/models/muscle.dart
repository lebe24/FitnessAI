/// A muscle the body map can draw and select.
///
/// [slug] is the key of this muscle's outlines in assets/data/body_map.json,
/// the MuscleMap geometry (MIT, see NOTICE.md), so renaming one here without
/// the asset breaks the drawing silently: the muscle simply stops appearing.
///
/// Deliberately not a port of Iron Index's src/lib/muscles.js. That file came
/// from openGym, which is AGPL v3.0, and AGPL code cannot go into a
/// closed-source App Store build. Only the geometry's own keys and ordinary
/// muscle names are used here. openGym's spelling table and coverage shading
/// are not.
class Muscle {
  final String slug;
  final String name;

  /// Goes in front of the YouTube query. Uses gym vocabulary where that finds
  /// better videos than the display name: "Traps" is a label, "trap" is what
  /// people actually search for.
  final String searchTerm;

  const Muscle(this.slug, this.name, this.searchTerm);

  /// Head to toe, which is the order every list of muscles is shown in.
  static const all = <Muscle>[
    Muscle('trapezius', 'Traps', 'trap'),
    Muscle('deltoids', 'Shoulders', 'shoulder'),
    Muscle('chest', 'Chest', 'chest'),
    Muscle('upper-back', 'Upper back', 'upper back'),
    Muscle('serratus', 'Serratus', 'serratus anterior'),
    Muscle('biceps', 'Biceps', 'bicep'),
    Muscle('triceps', 'Triceps', 'tricep'),
    Muscle('forearm', 'Forearms', 'forearm'),
    Muscle('abs', 'Abs', 'abs'),
    Muscle('obliques', 'Obliques', 'oblique'),
    Muscle('lower-back', 'Lower back', 'lower back'),
    Muscle('gluteal', 'Glutes', 'glute'),
    Muscle('quadriceps', 'Quads', 'quad'),
    Muscle('hamstring', 'Hamstrings', 'hamstring'),
    Muscle('adductors', 'Adductors', 'adductor'),
    Muscle('hip-flexors', 'Hip flexors', 'hip flexor'),
    Muscle('calves', 'Calves', 'calf'),
    Muscle('tibialis', 'Shins', 'tibialis anterior'),
  ];

  static Muscle? bySlug(String? slug) {
    for (final m in all) {
      if (m.slug == slug) return m;
    }
    return null;
  }
}

/// Body parts drawn as the silhouette. They carry no training load, so they
/// are never shaded and never selectable.
const kInertBodyParts = <String>[
  'head', 'hair', 'neck', 'hands', 'feet', 'knees', 'ankles',
];
