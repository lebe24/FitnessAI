/// The looks the energy bot can take.
enum BotMascot {
  flame('Flame'),
  robot('Robot'),
  droplet('Droplet'),
  kettlebell('Kettlebell');

  const BotMascot(this.label);
  final String label;
}

/// What the user chose to call their bot and how it looks.
class BotSettings {
  static const defaultName = 'BeFit Bot';
  static const maxNameLength = 20;

  final String name;
  final BotMascot mascot;

  const BotSettings({this.name = defaultName, this.mascot = BotMascot.flame});

  /// Letters, numbers, spaces, apostrophes and hyphens, up to
  /// [maxNameLength]. Anything left empty becomes the default.
  static String cleanName(String raw) {
    var name = raw
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r"[^\p{L}\p{M}\p{N} '’\-]", unicode: true), '')
        .replaceAll(RegExp(r' +'), ' ')
        .trim();
    if (name.length > maxNameLength) {
      name = String.fromCharCodes(name.runes.take(maxNameLength)).trim();
    }
    return name.isEmpty ? defaultName : name;
  }

  BotSettings copyWith({String? name, BotMascot? mascot}) =>
      BotSettings(name: name ?? this.name, mascot: mascot ?? this.mascot);

  @override
  bool operator ==(Object other) => other is BotSettings && other.name == name && other.mascot == mascot;

  @override
  int get hashCode => Object.hash(name, mascot);
}
