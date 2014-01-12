import 'dart:html';
import 'dart:math';

final int WIDTH  = 647;
final int HEIGHT = 400;
final int CELL_SIZE    = 25;
final int CELL_PADDING = 5;

int frame = 0;

ImageElement flowerBlue;
ImageElement flowerGreen;
ImageElement flowerRed;
ImageElement flowerWhite;
ImageElement flowerYellow;
void main() {
  CanvasElement canvas = querySelector("#game");
  canvas..width  = WIDTH
        ..height = HEIGHT
        ..style.marginLeft = "-${WIDTH  / 2}px"
        ..style.marginTop  = "-${HEIGHT / 2}px";
  flowerBlue = new ImageElement(src: "flowerBlue.png");
  flowerGreen = new ImageElement(src: "flowerGreen.png");
  flowerRed = new ImageElement(src: "flowerRed.png");
  flowerWhite = new ImageElement(src: "flowerWhite.png");
  flowerYellow = new ImageElement(src: "flowerYellow.png");
  new Game(canvas).start();
}

int count(List<Coords> l, Coords item) {
  int c = 0;
  for (Coords i in l) {
    if (i == item) c++;
  }
  return c;
}

class Colour {
  num r, g, b;
  Colour(this.r, this.g, this.b);
}

Colour goodColour() {
  Random r = new Random();
  return new Colour(r.nextInt(255), r.nextInt(255), r.nextInt(255));
}

String rgb(num r, num g, num b) {
  int R = min(255, r.round());
  int G = min(255, g.round());
  int B = min(255, b.round());
  return "rgb($R, $G, $B)";
}

abstract class Drawable {
  /// An object which can be drawn onto the game canvas.
  void draw(CanvasRenderingContext2D);
}

class Coords {
  num x, y;
  Coords(this.x, this.y);
  String toString() {
    return "Coords($x, $y)";
  }
  Coords clone() {
    return new Coords(this.x, this.y);
  }
  bool operator==(Coords other) {
    return x == other.x && y == other.y;
  }
}

class Flower {
  Coords coords;
  int type;
  Flower(this.coords, this.type);
}

class Dialogue implements Drawable {
  /// A dialogue box.
  num x, y, width, height;
  String title, message;
  Dialogue(this.x, this.y, this.width, this.height, this.title, this.message);
  void draw(CanvasRenderingContext2D ctx) {
    ctx.save();
    ctx.fillStyle = "#f8f8ff";
    ctx.fillRect(this.x, this.y, this.width, this.height);
    
    ctx.fillStyle = "#000";
    ctx.font = "bold 16px Arial, sans-serif";
    ctx.fillText(title, this.x + 5, this.y + 2);
    // TODO: text wrapping
    ctx.font = "12px Arial, sans-serif";
    ctx.fillText(message, this.x + 5, this.y + 20);
    ctx.restore();
  }
}

class Field implements Drawable {
  /// The map on which all the terrain and objects (`Cell`s) reside.
  List<Cell> map;
  List<Flower> flowerPositions = [];
  
  Field(this.map) {
    Random r = new Random();
    for (int i = 0; i < r.nextInt(10) + 20; i++) {
      flowerPositions.add(new Flower(new Coords(r.nextInt(WIDTH), r.nextInt(HEIGHT)), r.nextInt(4)));
    }
  }
  
  void draw(CanvasRenderingContext2D ctx) {
    ctx.save();
    for (Flower i in flowerPositions) {
      ctx.drawImage([flowerBlue, flowerGreen, flowerRed, flowerWhite, flowerYellow][i.type], i.coords.x, i.coords.y); // TODO: check for loadedness
    }
    for (num idx = 0; idx < map.length; idx++) {
      Cell cell = map[idx];
      cell.draw(ctx);
    }
    ctx.restore();
  }
}

class Cell implements Drawable {
  num x, y;
  num terrain = 0;
  Cell(this.x, this.y, [this.terrain = 0]);
  
  void draw(CanvasRenderingContext2D ctx) {
    ctx.save();
    if (terrain != 0) { // TODO: add more terrain types
      ctx.fillRect(
          this.x * CELL_SIZE + CELL_PADDING * this.x + 50,
          this.y * CELL_SIZE + CELL_PADDING * this.y + 50,
          CELL_SIZE, CELL_SIZE);
      ctx.fillStyle = "rgba(255, 255, 255, 0.4)";
    }
    ctx.restore();
  }
}

class Unit implements Drawable {
  List<Coords> parts;
  Colour colour;
  num id;
  num maxHealth = 7;
  Coords head;
  Unit(this.parts, this.id, [this.colour]) {
    head = parts[0];
  }
  
  void draw(CanvasRenderingContext2D ctx, [bool selected = false]) {
    ctx.save();
    num r = colour.r;
    num g = colour.g;
    num b = colour.b;
    for (num idx = 0; idx < parts.length; idx++) {
      List<Coords> parts2 = [];
      for (var i in parts) parts2.add(i.clone());
      parts2.sort((a, b) => a.x == b.x ? a.y - b.y : a.x - b.x);
      Coords part = parts2[idx];
      num extra = selected && new Coords(part.x, part.y) == head ? (frame % 60 - 30).abs() * 1.4 : 0;
      for (num i = 0; i > -3; i--) {
        ctx.fillStyle = [rgb(r * 0.5 + extra, g * 0.5 + extra, b * 0.5 + extra),
                         rgb(r * 0.7 + extra, g * 0.7 + extra, b * 0.7 + extra),
                         rgb(r *   1 + extra, g *   1 + extra, b *   1 + extra),][-i];
        ctx.fillRect(part.x * CELL_SIZE + CELL_PADDING * part.x + 50 + i,
                     part.y * CELL_SIZE + CELL_PADDING * part.y + 50 + i,
                     CELL_SIZE, CELL_SIZE);
        ctx.fillStyle = [rgb(r * 0.5, g * 0.5, b * 0.5),
                         rgb(r * 0.7, g * 0.7, b * 0.7),
                         rgb(r *   1, g *   1, b *   1),][-i];
        if (parts.contains(new Coords(part.x, part.y + 1))) {
          ctx.fillRect(part.x * (CELL_SIZE + CELL_PADDING) + CELL_SIZE/2 - CELL_PADDING/2 + 50 + i,
                       part.y * (CELL_SIZE + CELL_PADDING) + CELL_SIZE + 50 + i,
                       CELL_PADDING, CELL_PADDING);
        }
        if (parts.contains(new Coords(part.x - 1, part.y))) {
          ctx.fillRect(part.x * (CELL_SIZE + CELL_PADDING) - CELL_PADDING + 50 + i,
                       part.y * (CELL_SIZE + CELL_PADDING) + CELL_SIZE/2 - CELL_PADDING/2 + 50 + i,
                       CELL_PADDING, CELL_PADDING);
        }
      }
      ctx.fillStyle = "black";
      ctx.font = "12px Arial, sans-serif";
      ctx.fillText("[$idx]", part.x * (CELL_SIZE + CELL_PADDING) + 50, part.y * (CELL_SIZE + CELL_PADDING) + 50);
    }
    //ctx.fillStyle = "black";
    //ctx.font = "12px Arial, sans-serif";
    //ctx.fillText("[${this.id}]", head.x * (CELL_SIZE + CELL_PADDING) + 50, head.y * (CELL_SIZE + CELL_PADDING) + 50);
    ctx.restore();
  }
  
  void move(Coords loc) {
    if (parts.contains(loc)) {
      int loci = parts.indexOf(loc);
      int headi = parts.indexOf(head);
      print("Switching $loci and $headi");
      Coords Loc = loc;
      Coords Head = head;
      parts[loci] = Head;
      parts[headi] = Loc;
      head = parts[headi];
      return;
    }
    parts.insert(0, loc);
    head = parts[0];
    if (parts.length > maxHealth) {
      parts.removeLast();
    }
  }
}

final level1 = [
  "   ###   ",
  "  #####  ",
  " ####### ",
  "#########",
];

Field makeField(List<String> level) {
  Field f = new Field([]);
  for (num i = 0; i < level.length; i++) {
    for (num j = 0; j < level[i].length; j++) {
      if (level[i][j] != ' ') f.map.add(new Cell(j, i));
    }
  }
  return f;
}

class Game {
  /// The main game class that handles the drawing of all objects on the screen and the logic of the game itself.
  CanvasElement canvas;
  CanvasRenderingContext2D ctx;
  Field field;
  List<Unit> units = [
    new Unit([new Coords(6, 0), new Coords(5, 2), new Coords(5, 0), new Coords(5, 1), new Coords(6, 1), new Coords(4, 1)], 0,
      new Colour(255, 127, 0)),
    new Unit([new Coords(6, 6), new Coords(5, 8), new Coords(5, 6), new Coords(5, 7), new Coords(6, 7), new Coords(4, 7)], 1,
      new Colour(127, 255, 0)),
        
  ];
  List<Dialogue> drawables = [];
  int selectedId;
  Unit get selected {return units[selectedId];}
  void set selected(Unit val) {units[selectedId] = val;}
  Game(this.canvas) {
    ctx = canvas.getContext('2d');
    selectedId = 0;
    document.onKeyDown.listen(onKey);
    // Initial stuffs
    ctx.textBaseline = "top";
    field = makeField(level1);
  }
  
  void onKey(KeyboardEvent e) {
    e.preventDefault();
    switch (e.which) {
      case 39: selected.move(new Coords(selected.head.x + 1, selected.head.y    )); break;
      case 37: selected.move(new Coords(selected.head.x - 1, selected.head.y    )); break;
      case 38: selected.move(new Coords(selected.head.x    , selected.head.y - 1)); break;
      case 40: selected.move(new Coords(selected.head.x    , selected.head.y + 1)); break;
      case 9:  selectedId = (selectedId + 1) % units.length; break;
    }
  }
  
  start() {
    requestRedraw();
  }
  
  void draw(num _) {
    ctx.clearRect(0, 0, WIDTH, HEIGHT);
    ctx.fillStyle = '#2a3';
    ctx.fillRect(0, 0, WIDTH, HEIGHT);
    field.draw(ctx);
    for (var unit in units) {
      unit.draw(ctx, unit == selected);
    }
    for (var drawable in drawables) {
      drawable.draw(ctx);
    }
    requestRedraw();
  }
  
  void requestRedraw() {
    window.requestAnimationFrame(draw);
    frame++;
  }
}