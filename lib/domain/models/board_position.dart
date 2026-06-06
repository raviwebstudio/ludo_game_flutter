class BoardPosition {
  final int x;
  final int y;

  const BoardPosition(this.x, this.y);

  factory BoardPosition.fromJson(Map<String, dynamic> json) {
    return BoardPosition(
      json['x'] as int,
      json['y'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is BoardPosition && runtimeType == other.runtimeType && x == other.x && y == other.y;

  @override
  String toString() => "($x,$y)";

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}