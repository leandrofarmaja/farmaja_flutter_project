import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/supabase_database_service.dart';
import '../../domain/pharmacy_model.dart';
import '../../../reviews/presentation/widgets/pharmacy_reviews_list_widget.dart';

class PharmaciesScreen extends StatefulWidget {
  const PharmaciesScreen({super.key});

  @override
  State<PharmaciesScreen> createState() => _PharmaciesScreenState();
}

class _PharmaciesScreenState extends State<PharmaciesScreen> {
  final SupabaseDatabaseService _db = SupabaseDatabaseService();

  List<PharmacyModel> _pharmacies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPharmacies();
  }

  Future<void> _loadPharmacies() async {
    try {
      final pharmacies = await _db.getAllPharmacies();

      if (mounted) {
        setState(() {
          _pharmacies = pharmacies;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Farmácias',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryDark,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _pharmacies.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhuma farmácia encontrada.',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPharmacies,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pharmacies.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final pharm = _pharmacies[index];

                      return Card(
                        elevation: 1,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.white,
                              builder: (context) {
                                return SafeArea(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: SingleChildScrollView(
                                      child: PharmacyReviewsListWidget(
                                        pharmacyId: pharm.id,
                                        pharmacyName: pharm.name,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.local_pharmacy_rounded,
                                    color: AppColors.primary,
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pharm.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        pharm.address,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star_rounded,
                                            size: 18,
                                            color: Colors.amber,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            pharm.rating.toStringAsFixed(1),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          if (pharm.isOpen24h)
                                            const Text(
                                              '24h',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                              ),
                                            ),
                                          if (pharm.hasDelivery) ...[
                                            const SizedBox(width: 10),
                                            const Icon(
                                              Icons.delivery_dining_rounded,
                                              size: 18,
                                              color: Colors.blue,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
