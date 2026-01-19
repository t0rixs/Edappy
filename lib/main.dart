import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'game/flappy_game.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://grbxtyiwyzkjwprzmbyu.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdyYnh0eWl3eXprandwcnptYnl1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg3ODEwOTQsImV4cCI6MjA4NDM1NzA5NH0.XN0IFan2Da6vQrWt71HeTJ1vHYQMDcZT43A2MNHHEVY',
  );
  runApp(const MaterialApp(home: FlappyGame()));
}
