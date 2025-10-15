import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Wichtig für den Liquid-Look
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.black.withOpacity(0.3),
            expandedHeight: 120.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                "Good Evening",
                style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
              ),
              background: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("Recently Played"),
                  _buildHorizontalList(),
                  const SizedBox(height: 32),
                  _buildSectionTitle("Made For You"),
                  _buildVerticalList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, left: 8.0),
      child: Text(
        title,
        style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Widget _buildHorizontalList() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) {
          return _buildGlassCard(
            width: 140,
            title: "Album ${index + 1}",
            subtitle: "Artist Name",
          );
        },
      ),
    );
  }

   Widget _buildVerticalList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _buildGlassCard(
            height: 100,
            title: "Daily Mix ${index + 1}",
            subtitle: "A mix of your favorite tracks",
            isHorizontal: true,
          ),
        );
      },
    );
  }

  Widget _buildGlassCard({
    double? width,
    double? height,
    required String title,
    required String subtitle,
    bool isHorizontal = false,
  }) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.only(right: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: isHorizontal 
              ? Row(
                  children: [
                    Container(width: 100, color: Colors.primaries[title.hashCode % Colors.primaries.length].withOpacity(0.4)),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(title, style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 4),
                            Text(subtitle, style: GoogleFonts.manrope(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.primaries[title.hashCode % Colors.primaries.length].withOpacity(0.4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(title, style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: GoogleFonts.manrope(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
          ),
        ),
      ),
    );
  }
}

