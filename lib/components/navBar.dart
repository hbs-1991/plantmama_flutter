import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NavBarWidget extends StatefulWidget {
  const NavBarWidget({
    super.key,
    this.pageTitle = '',
    this.page,
  });

  final String pageTitle;
  final String? page;

  @override
  State<NavBarWidget> createState() => _NavBarWidgetState();
}

class _NavBarWidgetState extends State<NavBarWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SvgPicture.asset(
              'assets/images/intrologo.svg',
              width: 250,
              height: 125,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}
