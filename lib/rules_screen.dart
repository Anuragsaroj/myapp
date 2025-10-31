import 'package:flutter/material.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rules'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          ExpansionTile(
            leading: Icon(Icons.gamepad_outlined),
            title: Text('Gameplay Rules', style: TextStyle(fontWeight: FontWeight.bold)),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'The objective of Sudoku is to fill a 9x9 grid with digits so that each column, each row, and each of the nine 3x3 subgrids that compose the grid contain all of the digits from 1 to 9. The puzzle setter provides a partially completed grid, which for a well-posed puzzle has a single solution.',
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ExpansionTile(
            leading: Icon(Icons.star_outline),
            title: Text('Scoring Logic', style: TextStyle(fontWeight: FontWeight.bold)),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Your score is calculated based on several factors:\n\n'
                  '- Base Score: You receive a base score of 200 points for successfully completing a puzzle.\n'
                  '- Time Bonus: An additional bonus is awarded based on how quickly you solve the puzzle. The faster you are, the higher the bonus!\n'
                  '- Difficulty Multiplier: Harder difficulties may offer a score multiplier.',
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ExpansionTile(
            leading: Icon(Icons.lightbulb_outline),
            title: Text('Hints and Constraints', style: TextStyle(fontWeight: FontWeight.bold)),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'To help you on your journey, you have a few tools at your disposal:\n\n'
                  '- Hints: You can use up to 3 hints per game. A hint will reveal the correct digit for a random empty cell. Use them wisely!\n'
                  '- No More Hints: Once you have used all your hints, the hint option will be disabled for the remainder of the game.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
