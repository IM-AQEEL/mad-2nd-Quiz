import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const FlashcardApp());
}

class Flashcard {
  final String id;
  String question;
  String answer;
  bool isLearned;
  Flashcard({
    required this.id,
    required this.question,
    required this.answer,
    this.isLearned = false,
  });
}

class FlashcardApp extends StatelessWidget {
  const FlashcardApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flashcard Quiz',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: false, // Using Material 2 AppBar style for better visibility of the SliverAppBar
      ),
      home: const FlashcardScreen(),
    );
  }
}

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});
  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  // 1. Initial Data Set
  List<Flashcard> _flashcards = [
    Flashcard(id: '1', question: 'What is the capital of France?', answer: 'Paris', isLearned: true),
    Flashcard(id: '2', question: 'What is the chemical symbol for Gold?', answer: 'Au'),
    Flashcard(id: '3', question: 'What planet is known as the Red Planet?', answer: 'Mars'),
    Flashcard(id: '4', question: 'What is 7 times 8?', answer: '56'),
  ];
  // Key for AnimatedList insertion
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  // Track revealed state for each card
  final Map<String, bool> _revealedAnswers = {};
  // Track if a card has been "attempted" or viewed
  final Map<String, int> _attemptCount = {};

  @override
  void initState() {
    super.initState();
    // Initialize revealed state and attempt count for existing cards
    for (var card in _flashcards) {
      _revealedAnswers[card.id] = false;
      _attemptCount[card.id] = card.isLearned ? 3 : 0; // Pre-fill learned cards with max attempts
    }
  }

  // --- Core Methods ---
  // 2. Pull down to refresh list
  Future<void> _refreshList() async {
    // Simulate fetching a new quiz set
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _flashcards = [
        Flashcard(id: '5', question: 'What is the largest ocean?', answer: 'Pacific Ocean'),
        Flashcard(id: '6', question: 'Who wrote "Romeo and Juliet"?', answer: 'Shakespeare'),
        Flashcard(id: '7', question: 'What is the main component of Earth\'s atmosphere?', answer: 'Nitrogen'),
        Flashcard(id: '8', question: 'What year did the Titanic sink?', answer: '1912'),
      ];
      _revealedAnswers.clear();
      _attemptCount.clear();
      for (var card in _flashcards) {
        _revealedAnswers[card.id] = false;
        _attemptCount[card.id] = 0;
      }
    });
  }

  // 3. Add new question dynamically (AnimatedList insertion)
  void _addNewQuestion() {
    final newIndex = _flashcards.length;
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newCard = Flashcard(
      id: newId,
      question: 'New Dynamic Question: ${newIndex + 1}?',
      answer: 'Dynamic Answer: ${newIndex + 1}!',
    );
    // Update state first
    _flashcards.add(newCard);
    _revealedAnswers[newId] = false;
    _attemptCount[newId] = 0;

    // Trigger AnimatedList insertion animation
    _listKey.currentState!.insertItem(
      newIndex,
      duration: const Duration(milliseconds: 500),
    );
  }

  // 4. Handle card dismissal (Swipe to mark "learned")
  void _dismissCard(int index) {
    // 1. Mark card as learned before removing
    _flashcards[index].isLearned = true;
    final removedItem = _flashcards[index];
    final removedId = removedItem.id;

    // 2. Remove from data list
    _flashcards.removeAt(index);
    _revealedAnswers.remove(removedId);
    _attemptCount.remove(removedId);

    // 3. Trigger AnimatedList removal animation
    _listKey.currentState!.removeItem(
      index,
      (context, animation) => _buildFlashcardItem(
        removedItem,
        animation,
        index, // Use old index for key
      ),
      duration: const Duration(milliseconds: 500),
    );
    // Trigger a rebuild to update the progress bar immediately
    setState(() {});
  }

  // 5. Build the individual list item (for AnimatedList) - THIS IS THE ENHANCED CODE
  Widget _buildFlashcardItem(Flashcard card, Animation<double> animation, int index) {
    // Get attempt count, maximum is set to 3 for visual effect
    final attempts = _attemptCount[card.id] ?? 0;
    const maxAttempts = 3;
    final progressValue = min(attempts / maxAttempts, 1.0);
    
    // Determine status color and icon
    Color statusColor;
    IconData statusIcon;
    if (card.isLearned || attempts >= maxAttempts) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (attempts > 0) {
      statusColor = Colors.orange;
      statusIcon = Icons.visibility;
    } else {
      statusColor = Colors.blueGrey;
      statusIcon = Icons.lightbulb_outline;
    }

    // Use a SizeTransition for the insertion/removal animation
    return SizeTransition(
      key: ValueKey(card.id),
      sizeFactor: animation,
      axisAlignment: 0.0,
      child: Dismissible(
        // Key is required for Dismissible
        key: Key(card.id),
        direction: DismissDirection.startToEnd,
        // Feedback when swiping
        background: Container(
          color: Colors.green,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20.0),
          child: const Row(
            children: [
              Icon(Icons.check, color: Colors.white),
              SizedBox(width: 8),
              Text('Learned', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        // Action when dismissal is confirmed
        onDismissed: (direction) {
          _dismissCard(index);
        },
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: 2,
          child: InkWell( // Use InkWell for better visual feedback on tap
            onTap: () {
              setState(() {
                // Toggle revealed state
                _revealedAnswers[card.id] = !(_revealedAnswers[card.id] ?? false);
                
                // Increment attempt/view count only if revealing the answer
                if (_revealedAnswers[card.id] == true && attempts < maxAttempts) {
                  _attemptCount[card.id] = attempts + 1;
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    // Leading: Custom progress/status indicator
                    leading: SizedBox(
                      width: 50,
                      height: 50,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Circular Progress Bar
                          CircularProgressIndicator(
                            value: progressValue,
                            strokeWidth: 4,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                          ),
                          // Status Icon
                          Icon(statusIcon, size: 24, color: statusColor.withOpacity(0.8)),
                        ],
                      ),
                    ),
                    
                    // Title: Question text
                    title: Text(
                      card.question, 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    
                    // Trailing: Reveal icon
                    trailing: Icon(
                      (_revealedAnswers[card.id] ?? false) ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    ),
                  ),

                  // Subtitle area with AnimatedCrossFade for the Answer
                  AnimatedCrossFade(
                    // Show answer only if revealed state is true
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(top: 8.0, left: 72.0, right: 16.0), // Align with title text
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Answer:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo.shade700)),
                          Text(
                            card.answer, 
                            style: const TextStyle(color: Colors.indigo, fontSize: 16),
                          ),
                          const SizedBox(height: 8.0),
                          // Additional detail (using RichText for emphasis)
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                              children: [
                                const TextSpan(text: 'Times viewed: '),
                                TextSpan(
                                  text: '$attempts',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: statusColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    crossFadeState: (_revealedAnswers[card.id] ?? false)
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate progress for the SliverAppBar
    final learnedCards = _flashcards.where((card) => card.isLearned).length;
    final totalCards = _flashcards.length + learnedCards;
    final progressText = '${learnedCards} of ${totalCards} learned';
    final progressValue = totalCards > 0 ? learnedCards / totalCards : 0.0;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewQuestion,
        icon: const Icon(Icons.add),
        label: const Text('Add Card'),
      ),
      // Use RefreshIndicator for pull-to-refresh
      body: RefreshIndicator(
        onRefresh: _refreshList,
        // Use CustomScrollView for the Collapsing Header (SliverAppBar)
        child: CustomScrollView(
          // 6. Proper Scrolling Behavior (provided by CustomScrollView)
          slivers: <Widget>[
            // 5. Optional: Use a collapsing header (SliverAppBar) that shows progress
            SliverAppBar(
              expandedHeight: 180.0, // Increased height for more space
              pinned: true,
              backgroundColor: Colors.indigo,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: false,
                titlePadding: EdgeInsets.only(left: 16, bottom: 16),
                title: Text(
                  'Flashcard Quiz ',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
                background: Container(
                  padding: const EdgeInsets.only(top: 50.0, left: 16.0, right: 16.0),
                  alignment: Alignment.bottomLeft,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Cards: $totalCards',
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Progress: $progressText',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progressValue,
                        minHeight: 8.0,
                        backgroundColor: Colors.white30,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.lightGreenAccent),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
            // Use SliverAnimatedList to demonstrate animated updates
            SliverAnimatedList(
              key: _listKey,
              initialItemCount: _flashcards.length,
              // 7. List updates with animation (via AnimatedList)
              itemBuilder: (context, index, animation) {
                // We must use the current index to safely access the list in builder
                if (index >= _flashcards.length) return const SizedBox.shrink();
                return _buildFlashcardItem(_flashcards[index], animation, index);
              },
            ),
            // Add a small sliver at the end if the list is short, so the FAB doesn't cover the last card
            SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
    );
  }
}