import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class Loading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFFE8E8E8), //Colors.grey[200],
      child: Center(
        child: SpinKitWave(color: Color(0xFFCF118C))
      ),
    );
  }
}