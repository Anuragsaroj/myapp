import 'package:flutter/material.dart';

class AwardsScreen extends StatefulWidget {
  const AwardsScreen({super.key});

  @override
  State<AwardsScreen> createState() => _AwardsScreenState();
}

class _AwardsScreenState extends State<AwardsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Awards'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Badges'),
            Tab(text: 'Streaks'),
            Tab(text: 'Challenges'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBadgesGrid(),
          _buildStreaksList(),
          _buildChallengesList(),
        ],
      ),
    );
  }

  Widget _buildBadgesGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        return ScaleTransition(
          scale: _animation,
          child: _buildBadgeItem(index),
        );
      },
    );
  }

  Widget _buildBadgeItem(int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star,
            size: 40,
            color: index % 2 == 0 ? Colors.amber : Colors.grey,
          ),
          const SizedBox(height: 8),
          Text(
            'Badge ${index + 1}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStreaksList() {
    return FadeTransition(
      opacity: _animation,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: 5,
        itemBuilder: (context, index) {
          return _buildStreakItem(index);
        },
      ),
    );
  }

  Widget _buildStreakItem(int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.whatshot, color: Colors.orange),
        title: Text('Streak ${index + 1}'),
        subtitle: Text('${(index + 1) * 5} days'),
        trailing: const Icon(Icons.check_circle, color: Colors.green),
      ),
    );
  }

  Widget _buildChallengesList() {
    return FadeTransition(
      opacity: _animation,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: 3,
        itemBuilder: (context, index) {
          return _buildChallengeItem(index);
        },
      ),
    );
  }

  Widget _buildChallengeItem(int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.military_tech, color: Colors.blue),
        title: Text('Challenge ${index + 1}'),
        subtitle: const Text('Completed'),
        trailing: const Icon(Icons.check_circle, color: Colors.green),
      ),
    );
  }
}
