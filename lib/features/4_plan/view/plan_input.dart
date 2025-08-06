import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fyp_proj/features/4_plan/ViewModel/generating_viewModel.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Import package
import 'generating_screen.dart';
import 'package:google_places_flutter/google_places_flutter.dart';

enum Budget { low, middle, high }

class TripInputScreen extends StatefulWidget {
  const TripInputScreen({super.key});

  @override
  State<TripInputScreen> createState() => _TripInputScreenState();
}

class _TripInputScreenState extends State<TripInputScreen> {
  final TextEditingController _cityTextController = TextEditingController();
  final String _placesApiKey =
      dotenv.env['PLACES_API_KEY'] ?? 'API_KEY_NOT_FOUND';

  String? _selectedCity;
  Set<Budget> _selectedBudget = {Budget.middle};
  double _historyPreference = 50.0;
  double _artsPreference = 50.0;
  double _foodPreference = 50.0;

  @override
  void dispose() {
    _cityTextController.dispose();
    super.dispose();
  }

  void _navigateToGeneratingScreen() async {
    if (_selectedCity == null || _selectedCity!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a city from the list.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Get the FCM token
    String? fcmToken = await FirebaseMessaging.instance.getToken();

    if (fcmToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not register for notifications. Please try again.',
          ),
        ),
      );
      return;
    }

    final request =
        'I want a trip with a focus on: History (${_historyPreference.round()}), '
        'Arts (${_artsPreference.round()}), and Food (${_foodPreference.round()}).';

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => ChangeNotifierProvider(
              create: (context) => GeneratingViewModel(),
              child: GeneratingScreen(
                city: _selectedCity!,
                budget: _selectedBudget.first.name,
                request: request,
                fcmToken: fcmToken, // Pass the token
              ),
            ),
      ),
    );
  }

  Widget _buildPreferenceSlider({
    required String title,
    required IconData icon,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20.0,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            Text(
              '${value.round()}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(
          value: value,
          min: 0,
          max: 100,
          divisions: 10,
          label: value.round().toString(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('Places API Key: $_placesApiKey');
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Travel Planner'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      // 1. Use a Column for the main body structure.
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 2. Place the non-scrolling widgets directly in the Column.
            Text('City', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Theme(
              // 2. このウィジェットにだけ適用される新しいテーマデータを作成
              data: Theme.of(context).copyWith(
                // 3. 入力フィールドのテーマを上書き
                inputDecorationTheme: const InputDecorationTheme(
                  // 4. アプリ全体のテーマが適用する枠線を「なし」に設定
                  border: InputBorder.none,
                ),
              ),
              child: GooglePlaceAutoCompleteTextField(
                textEditingController: _cityTextController,
                googleAPIKey: _placesApiKey,
                inputDecoration: InputDecoration(),
                debounceTime: 800,
                countries: ["my","in", "fr"], // optional by default null is set
                isLatLngRequired:
                    true, // if you required coordinates from place detail
                getPlaceDetailWithLatLng: (Prediction prediction) {
                  print("placeDetails" + prediction.lng.toString());
                }, // this callback is called when isLatLngRequired is true
                itemClick: (Prediction prediction) {
                  _cityTextController.text = prediction.description!;
                  _selectedCity = prediction.description;
                  _cityTextController.selection = TextSelection.fromPosition(
                    TextPosition(offset: prediction.description!.length),
                  );
                },
                // if we want to make custom list item builder
                itemBuilder: (context, index, Prediction prediction) {
                  return Container(
                    padding: EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Icon(Icons.location_on),
                        SizedBox(width: 7),
                        Expanded(
                          child: Text("${prediction.description ?? ""}"),
                        ),
                      ],
                    ),
                  );
                },
                seperatedBuilder: Divider(),
                isCrossBtnShown: true,
                containerHorizontalPadding: 10,
              ),
            ),
            const SizedBox(height: 24),

            // 3. Use Expanded and ListView for the rest of the content to make it scrollable.
            Expanded(
              child: ListView(
                children: [
                  Text(
                    'Budget Level',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<Budget>(
                    segments: const [
                      ButtonSegment<Budget>(
                        value: Budget.low,
                        label: Text('Low'),
                        icon: Icon(Icons.attach_money),
                      ),
                      ButtonSegment<Budget>(
                        value: Budget.middle,
                        label: Text('Middle'),
                        icon: Icon(Icons.money),
                      ),
                      ButtonSegment<Budget>(
                        value: Budget.high,
                        label: Text('High'),
                        icon: Icon(Icons.diamond),
                      ),
                    ],
                    selected: _selectedBudget,
                    onSelectionChanged: (Set<Budget> newSelection) {
                      setState(() {
                        _selectedBudget = newSelection;
                      });
                    },
                    // ... your button styles
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Preferences',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  _buildPreferenceSlider(
                    title: 'History',
                    icon: Icons.account_balance,
                    value: _historyPreference,
                    onChanged: (newValue) {
                      setState(() {
                        _historyPreference = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildPreferenceSlider(
                    title: 'Arts & Culture',
                    icon: Icons.palette,
                    value: _artsPreference,
                    onChanged: (newValue) {
                      setState(() {
                        _artsPreference = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildPreferenceSlider(
                    title: 'Food & Dining',
                    icon: Icons.restaurant,
                    value: _foodPreference,
                    onChanged: (newValue) {
                      setState(() {
                        _foodPreference = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _navigateToGeneratingScreen,
                      child: const Text('Generate Plan'),
                    ),
                  ),
                  const SizedBox(height: 16), // Add some padding at the bottom
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
