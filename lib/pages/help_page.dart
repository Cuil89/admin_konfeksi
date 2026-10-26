import 'package:flutter/material.dart';

import '../core/app_icons.dart';
import '../core/theme.dart';
import '../widgets/app_card.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 28,
            vertical: 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pusat Bantuan', style: AppText.pageTitle),
                  const SizedBox(height: 4),
                  const Text(
                    'Panduan penggunaan sistem payroll, kalkulasi matematis, dan kontak tim dukungan.',
                    style: AppText.small,
                  ),

                  const SizedBox(height: 24),

                  // Contact Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(AppIcons.support, size: 28, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tim Dukungan Payrole Siap Membantu',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Butuh asistensi perhitungan pajak atau pelaporan akhir tahun? Hubungi tim HR konsultan kami.',
                                style: TextStyle(fontSize: 12.5, color: Color(0xFFD1FAE5)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // FAQ Section
                  const Text('Pertanyaan Umum & Rumus Perhitungan', style: AppText.sectionTitle),
                  const SizedBox(height: 16),

                  _faqItem(
                    'Bagaimana rumus perhitungan Gaji Bersih (Take Home Pay)?',
                    'Gaji Bersih = (Gaji Pokok + Tunjangan) − (BPJS Kesehatan + BPJS Ketenagakerjaan + PPh 21 + Potongan Kasbon/Bon + Potongan Lainnya).\n'
                    'Semua kalkulasi dilakukan secara otomatis dan presisi hingga bilangan bulat Rupiah tanpa floating point error.',
                  ),
                  _faqItem(
                    'Bagaimana integrasi kasbon ke tabel payroll bekerja?',
                    'Saat kasbon dicatat dengan opsi "Sinkronkan ke payroll", nominal cicilan per bulan akan otomatis ditambahkan ke komponen Potongan karyawan tersebut di tabel payroll, sehingga gaji bersih langsung terupdate real-time.',
                  ),
                  _faqItem(
                    'Bagaimana cara memproses payroll?',
                    'Klik tombol "Proses payroll" di kanan atas halaman Penggajian. Anda dapat memilih semua karyawan yang sudah siap dibayar. Karyawan yang berstatus "Perlu ditinjau" harus disetujui terlebih dahulu demi menjaga akurasi pembayaran.',
                  ),
                  _faqItem(
                    'Apakah slip gaji bisa dicetak atau diunduh?',
                    'Ya, klik menu titik tiga (...) pada baris karyawan mana pun dan pilih "Lihat slip gaji". Anda dapat langsung mencetak atau menyimpannya sebagai file PDF resmi.',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _faqItem(String q, String a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(AppIcons.info, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    q,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textStrong),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(a, style: const TextStyle(fontSize: 13, color: AppColors.text2, height: 1.45)),
          ],
        ),
      ),
    );
  }
}
