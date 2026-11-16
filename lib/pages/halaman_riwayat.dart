
import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/pesanan.dart';

class HalamanRiwayat extends StatefulWidget {
  const HalamanRiwayat({super.key});

  @override
  State<HalamanRiwayat> createState() => _HalamanRiwayatState();
}

class _HalamanRiwayatState extends State<HalamanRiwayat> {
  late Future<List<Pesanan>> _daftarPesanan;

  @override
  void initState() {
    super.initState();
    _daftarPesanan =
        DatabaseHelper.instance.ambilSemuaPesanan();
  }

  void _muatUlangData() {
    setState(() {
      _daftarPesanan =
          DatabaseHelper.instance.ambilSemuaPesanan();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pesanan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
            onPressed: _muatUlangData,
          ),
        ],
      ),
      body: FutureBuilder<List<Pesanan>>(
        future: _daftarPesanan,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            debugPrint(
              'ERROR RIWAYAT: ${snapshot.error}',
            );

            debugPrint(
              'STACK TRACE: ${snapshot.stackTrace}',
            );

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Gagal memuat riwayat pesanan.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _muatUlangData,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final daftar = snapshot.data ?? [];

          if (daftar.isEmpty) {
            return const Center(
              child: Text('Belum ada riwayat pesanan.'),
            );
          }

          return ListView.builder(
            itemCount: daftar.length,
            itemBuilder: (context, index) {
              final pesanan = daftar[index];

              return Dismissible(
                key: ValueKey(pesanan.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                onDismissed: (direction) async {
                  try {
                    await DatabaseHelper.instance
                        .hapusPesanan(pesanan.id!);

                    if (!mounted) return;

                    _muatUlangData();
                  } catch (e) {
                    debugPrint('ERROR DELETE: $e');

                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal menghapus pesanan: $e'),
                      ),
                    );

                    _muatUlangData();
                  }
                },
                child: ListTile(
                  title: Text(pesanan.ringkasanItem),
                  subtitle: Text(
                    '${pesanan.totalItem} item • ${pesanan.tanggal}',
                  ),
                  trailing: Text('Rp${pesanan.totalHarga}'),
                  onTap: () async {
                    final controller = TextEditingController(
                      text: pesanan.totalItem.toString(),
                    );

                    final jumlahBaru = await showDialog<int>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Ubah Jumlah Item'),
                          content: TextField(
                            controller: controller,
                            keyboardType: TextInputType.number,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('Batal'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(
                                  context,
                                  int.tryParse(controller.text),
                                );
                              },
                              child: const Text('Simpan'),
                            ),
                          ],
                        );
                      },
                    );

                    controller.dispose();

                    if (jumlahBaru == null || jumlahBaru <= 0) {
                      return;
                    }

                    try {
                      await DatabaseHelper.instance.ubahPesanan(
                        Pesanan(
                          id: pesanan.id,
                          ringkasanItem: pesanan.ringkasanItem,
                          totalItem: jumlahBaru,
                          totalHarga: pesanan.totalHarga,
                          tanggal: pesanan.tanggal,
                        ),
                      );

                      if (!mounted) return;

                      _muatUlangData();
                    } catch (e) {
                      debugPrint('ERROR UPDATE: $e');

                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal mengubah pesanan: $e'),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
