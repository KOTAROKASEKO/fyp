import 'package:flutter/material.dart';
import 'package:fyp_proj/features/4_plan/ViewModel/generating_viewModel.dart';
import 'package:provider/provider.dart';
import 'generating_screen.dart';

// Budget enum remains the same
enum Budget { low, middle, high }

class TripInputScreen extends StatefulWidget {
  const TripInputScreen({super.key});

  @override
  State<TripInputScreen> createState() => _TripInputScreenState();
}

class _TripInputScreenState extends State<TripInputScreen> {
  // Controller for the Autocomplete text field
  final TextEditingController _cityTextController = TextEditingController();
  
  // State variables for the new widgets
  String? _selectedCity; // To store the final selected city
  Set<Budget> _selectedBudget = {Budget.middle};
  double _historyPreference = 50.0;
  double _artsPreference = 50.0;
  double _foodPreference = 50.0;

  // --- NEW: A static list of cities for the autocomplete feature ---
  // In a real app, you might fetch this from an API
  static const List<String> _cities = <String>[
    'Kuala Lumpur',
    'Kagoshima',
    'Kyoto',
    'Kansas City',
    'Kolkata',
    'Tokyo',
    'Osaka',
    'Singapore',
    'Paris',
    'London',
    'New York',
  ];

  @override
  void dispose() {
    // Dispose the new controller as well
    _cityTextController.dispose();
    super.dispose();
  }

  void _navigateToGeneratingScreen() {
    // --- UPDATED: Validation logic ---
    if (_selectedCity == null || _selectedCity!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a city from the list.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // --- UPDATED: Format the preferences from sliders into a string ---
    final request =
        'I want a trip with a focus on: History (${_historyPreference.round()}), '
        'Arts (${_artsPreference.round()}), and Food (${_foodPreference.round()}).';

    // Navigate with the new data structure
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (context) => GeneratingViewModel(),
          child: GeneratingScreen(
            city: _selectedCity!, // Use the state variable
            budget: _selectedBudget.first.name,
            request: request, // Use the formatted preference string
          ),
        ),
      ),
    );
  }

  // --- NEW: A helper widget to build each preference slider ---
  // This avoids code repetition
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
                Icon(icon, size: 20.0, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            Text(
              '${value.round()}', // Display the rounded value
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Travel Planner'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- UPDATED: City Input now uses Autocomplete ---
          Text('City', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text == '') {
                return const Iterable<String>.empty();
              }
              return _cities.where((String option) {
                return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
              });
            },
            onSelected: (String selection) {
              setState(() {
                _selectedCity = selection;
              });
              debugPrint('You just selected $selection');
            },
            fieldViewBuilder: (BuildContext context, TextEditingController fieldController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
              // We use our own controller here to manage its lifecycle
              // This is where the text field is built
              return TextFormField(
                controller: fieldController,
                focusNode: fieldFocusNode,
                decoration: const InputDecoration(
                  hintText: 'e.g., Kuala Lumpur',
                  prefixIcon: Icon(Icons.location_city),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Budget selection remains the same
          Text('Budget Level', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<Budget>(
            segments: const [
              ButtonSegment<Budget>(value: Budget.low, label: Text('Low'), icon: Icon(Icons.attach_money)),
              ButtonSegment<Budget>(value: Budget.middle, label: Text('Middle'), icon: Icon(Icons.money)),
              ButtonSegment<Budget>(value: Budget.high, label: Text('High'), icon: Icon(Icons.diamond)),
            ],
            selected: _selectedBudget,
            onSelectionChanged: (Set<Budget> newSelection) {
              setState(() {
                _selectedBudget = newSelection;
              });
            },
            style: SegmentedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surface,
              selectedForegroundColor: Colors.black,
              selectedBackgroundColor: Colors.tealAccent,
            ),
            multiSelectionEnabled: false,
            emptySelectionAllowed: false,
          ),
          const SizedBox(height: 24),

          // --- UPDATED: User Request is now Preference Sliders ---
          Text('Preferences', style: Theme.of(context).textTheme.titleMedium),
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
        ],
      ),
    );
  }

}