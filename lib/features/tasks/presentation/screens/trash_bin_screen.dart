import 'package:flutter/material.dart';

class TrashBinScreen extends StatelessWidget {
  const TrashBinScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Trash Bin', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  SizedBox(height: 6),
                  Text('Deleted tasks · permanently removed after 90 days', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Container(
                decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFFDE68A))),
                padding: const EdgeInsets.all(14),
                child: const Text(
                  'Deleted tasks are kept here for 90 days for record-keeping. After that they are permanently removed.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF92400E), height: 1.5),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Align(alignment: Alignment.centerLeft, child: Text('3 Deleted Tasks', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                children: const [
                  _TrashRow(title: 'Safety checklist Zone C', subtitle: 'Deleted by J. Mokoena · Feb 20', days: '68 days left'),
                  _TrashRow(title: 'Monthly stock report', subtitle: 'Deleted by J. Mokoena · Jan 15', days: '34 days left'),
                  _TrashRow(title: 'Zone B deep clean', subtitle: 'Deleted by J. Mokoena · Jan 2', days: '21 days left'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrashRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String days;

  const _TrashRow({required this.title, required this.subtitle, required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🗑', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280), decoration: TextDecoration.lineThrough)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          Text(days, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFDC2626))),
        ],
      ),
    );
  }
}
