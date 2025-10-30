import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/swipe_provider.dart';
import '../models/offer.dart';
import '../models/formation.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CardSwiperController controller = CardSwiperController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final swipeProvider = Provider.of<SwipeProvider>(context, listen: false);
      if (authProvider.user != null) {
        swipeProvider.loadItems(authProvider.user!.userType);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final swipeProvider = Provider.of<SwipeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rezo'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        color: Colors.white,
        child: swipeProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : swipeProvider.error != null
                ? Center(child: Text('Erreur: ${swipeProvider.error}'))
                : swipeProvider.items.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun élément disponible',
                          style: TextStyle(color: Colors.black, fontSize: 18),
                        ),
                      )
                    : CardSwiper(
                        controller: controller,
                        cardsCount: swipeProvider.items.length,
                        onSwipe: _onSwipe,
                        numberOfCardsDisplayed: swipeProvider.items.length > 1 ? 2 : 1,
                        backCardOffset: const Offset(40, 40),
                        padding: const EdgeInsets.all(24.0),
                        cardBuilder: (context, index, horizontalThresholdPercentage, verticalThresholdPercentage) =>
                            _buildCard(swipeProvider.items[index]),
                      ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              // Déjà sur home
              break;
            case 1:
              Navigator.of(context).pushNamed('/chat');
              break;
            case 2:
              Navigator.of(context).pushNamed('/profile');
              break;
            case 3:
              Navigator.of(context).pushNamed('/settings');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Paramètres',
          ),
        ],
      ),
    );
  }

  Widget _buildCard(dynamic item) {
    String title = '';
    String description = '';
    String subtitle = '';

    if (item is Offer) {
      title = item.title;
      description = item.description;
      subtitle = 'Offre d\'emploi';
    } else if (item is Formation) {
      title = item.title;
      description = item.description;
      subtitle = 'Formation universitaire';
    }

    return Card(
      elevation: 8.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14.0,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: Text(
                description,
                style: const TextStyle(fontSize: 16.0),
                overflow: TextOverflow.ellipsis,
                maxLines: 10,
              ),
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => controller.swipe(CardSwiperDirection.left),
                  icon: const Icon(Icons.close),
                  label: const Text('Passer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => controller.swipe(CardSwiperDirection.right),
                  icon: const Icon(Icons.check),
                  label: const Text('Intéressé'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    final swipeProvider = Provider.of<SwipeProvider>(context, listen: false);
    final item = swipeProvider.items[previousIndex];

    if (direction == CardSwiperDirection.right) {
      swipeProvider.onSwipeRight(item);
    } else if (direction == CardSwiperDirection.left) {
      swipeProvider.onSwipeLeft(item);
    }

    return true;
  }
}
