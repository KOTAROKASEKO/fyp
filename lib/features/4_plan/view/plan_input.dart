import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fyp_proj/features/4_plan/ViewModel/generating_viewModel.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'generating_screen.dart';
import 'package:google_places_flutter/google_places_flutter.dart';

enum Budget { low, middle, high }
enum Occasion { dating, friends, family, solo }
enum Style { romantic, adventurous, relaxing }

class TripInputScreen extends StatefulWidget {
  const TripInputScreen({super.key});

  @override
  State<TripInputScreen> createState() => _TripInputScreenState();
}

class _TripInputScreenState extends State<TripInputScreen> {
  final TextEditingController _cityTextController = TextEditingController();
  // --- NEW: Controller for the new text field ---
  final TextEditingController _otherRequestController = TextEditingController();
  final String _placesApiKey =
      dotenv.env['PLACES_API_KEY'] ?? 'API_KEY_NOT_FOUND';

  String? _selectedCity;
  Set<Budget> _selectedBudget = {Budget.middle};
  Set<Occasion> _selectedOccasion = {Occasion.dating};
  Set<Style> _selectedStyle = {Style.romantic};
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 21, minute: 0);

  @override
  void dispose() {
    _cityTextController.dispose();
    // --- NEW: Dispose the new controller ---
    _otherRequestController.dispose();
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

    // --- NEW: Get text from the new controller ---
    final otherRequest = _otherRequestController.text.trim();

    // --- MODIFIED: Append the other request to the main prompt ---
    final request =
        'I want a trip for ${_selectedOccasion.first.name}, with a ${_selectedStyle.first.name} style. '
        'The budget is ${_selectedBudget.first.name}. '
        'The trip will be from ${_startTime.format(context)} to ${_endTime.format(context)}. '
        'My preferences are: History (${_historyPreference.round()}), '
        'Arts (${_artsPreference.round()}), and Food (${_foodPreference.round()}).'
        '${otherRequest.isNotEmpty ? ' Other specific requests: $otherRequest' : ''}';


    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (context) => GeneratingViewModel(),
          child: GeneratingScreen(
            city: _selectedCity!,
            budget: _selectedBudget.first.name,
            request: request,
            fcmToken: fcmToken,
          ),
        ),
      ),
    );
  }
  
  Future<void> _selectTime(BuildContext context, {required bool isStart}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  double _historyPreference = 50.0;
  double _artsPreference = 50.0;
  double _foodPreference = 50.0;

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Travel Planner'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('City', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Theme(
              data: Theme.of(context).copyWith(
                inputDecorationTheme: const InputDecorationTheme(
                  border: InputBorder.none,
                ),
              ),
              child: GooglePlaceAutoCompleteTextField(
                textEditingController: _cityTextController,
                googleAPIKey: _placesApiKey,
                inputDecoration: InputDecoration(),
                debounceTime: 800,
                countries: const ["my", "in", "fr"],
                isLatLngRequired: true,
                getPlaceDetailWithLatLng: (Prediction prediction) {},
                itemClick: (Prediction prediction) {
                  _cityTextController.text = prediction.description!;
                  _selectedCity = prediction.description;
                  _cityTextController.selection = TextSelection.fromPosition(
                    TextPosition(offset: prediction.description!.length),
                  );
                },
                itemBuilder: (context, index, Prediction prediction) {
                  return Container(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(prediction.description ?? ""),
                        ),
                      ],
                    ),
                  );
                },
                seperatedBuilder: const Divider(),
                isCrossBtnShown: true,
                containerHorizontalPadding: 10,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  Text('Occasion', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SegmentedButton<Occasion>(
                    segments: const [
                      ButtonSegment<Occasion>(value: Occasion.dating, label: Text('Dating'), icon: Icon(Icons.favorite)),
                      ButtonSegment<Occasion>(value: Occasion.friends, label: Text('Friends'), icon: Icon(Icons.group)),
                      ButtonSegment<Occasion>(value: Occasion.family, label: Text('Family'), icon: Icon(Icons.family_restroom)),
                      ButtonSegment<Occasion>(value: Occasion.solo, label: Text('Solo'), icon: Icon(Icons.person)), // solo を追加
                    ],
                    selected: _selectedOccasion,
                    onSelectionChanged: (newSelection) => setState(() => _selectedOccasion = newSelection),
                  ),
                  const SizedBox(height: 24),
                  
                  Text('Style', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SegmentedButton<Style>(
                    segments: const [
                      ButtonSegment<Style>(value: Style.romantic, label: Text('Romantic')),
                      ButtonSegment<Style>(value: Style.adventurous, label: Text('Adventurous')),
                      ButtonSegment<Style>(value: Style.relaxing, label: Text('Relaxing')),
                    ],
                    selected: _selectedStyle,
                    onSelectionChanged: (newSelection) => setState(() => _selectedStyle = newSelection),
                  ),
                  const SizedBox(height: 24),

                  Text('Duration', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _selectTime(context, isStart: true),
                        icon: const Icon(Icons.schedule),
                        label: Text('From: ${_startTime.format(context)}'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _selectTime(context, isStart: false),
                        icon: const Icon(Icons.schedule),
                        label: Text('To: ${_endTime.format(context)}'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Text('Budget Level', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SegmentedButton<Budget>(
                    segments: const [
                      ButtonSegment<Budget>(value: Budget.low, label: Text('Low'), icon: Icon(Icons.attach_money)),
                      ButtonSegment<Budget>(value: Budget.middle, label: Text('Middle'), icon: Icon(Icons.money)),
                      ButtonSegment<Budget>(value: Budget.high, label: Text('High'), icon: Icon(Icons.diamond)),
                    ],
                    selected: _selectedBudget,
                    onSelectionChanged: (newSelection) => setState(() => _selectedBudget = newSelection),
                  ),
                  const SizedBox(height: 24),

                  Text('Preferences', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  _buildPreferenceSlider(
                    title: 'History',
                    icon: Icons.account_balance,
                    value: _historyPreference,
                    onChanged: (newValue) => setState(() => _historyPreference = newValue),
                  ),
                  const SizedBox(height: 16),
                  _buildPreferenceSlider(
                    title: 'Arts & Culture',
                    icon: Icons.palette,
                    value: _artsPreference,
                    onChanged: (newValue) => setState(() => _artsPreference = newValue),
                  ),
                  const SizedBox(height: 16),
                  _buildPreferenceSlider(
                    title: 'Food & Dining',
                    icon: Icons.restaurant,
                    value: _foodPreference,
                    onChanged: (newValue) => setState(() => _foodPreference = newValue),
                  ),
                  const SizedBox(height: 24),

                  Text('Other Requests (Optional)', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _otherRequestController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '例: "夜景が綺麗な場所に行きたい", "ペット同伴OKのカフェを含めてほしい"',
                      helperText: '具体的な要望があればAIが考慮します',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _navigateToGeneratingScreen,
                      child: const Text('Generate Plan'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}