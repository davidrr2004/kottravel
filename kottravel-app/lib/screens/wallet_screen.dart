import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../utils/app_theme.dart';
import '../utils/responsive.dart';

class WalletScreen extends StatefulWidget {
  final String userId; // User ID to fetch wallet data

  const WalletScreen({
    super.key,
    this.userId = 'user001', // Default user ID for demo
  });

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool isLoading = true;
  String errorMessage = '';
  double creditBalance = 0.0;
  List<Map<String, dynamic>> transactionHistory = [];

  @override
  void initState() {
    super.initState();
    loadWalletData();
  }

  Future<void> loadWalletData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Reference to Firebase Database
      final databaseRef = FirebaseDatabase.instance.ref();

      // Get wallet data for the user
      final walletSnapshot =
          await databaseRef
              .child('users')
              .child(widget.userId)
              .child('wallet')
              .get();

      if (walletSnapshot.exists) {
        // Parse wallet data
        final walletData = Map<String, dynamic>.from(
          walletSnapshot.value as Map,
        );

        // Get credit balance
        creditBalance = (walletData['balance'] as num?)?.toDouble() ?? 0.0;
      } else {
        // If wallet doesn't exist, initialize it
        await databaseRef
            .child('users')
            .child(widget.userId)
            .child('wallet')
            .set({
              'balance': 0.0,
              'last_updated': DateTime.now().toIso8601String(),
            });
      }

      // Get transaction history
      final historySnapshot =
          await databaseRef
              .child('users')
              .child(widget.userId)
              .child('transactions')
              .get();

      if (historySnapshot.exists) {
        final historyData = Map<String, dynamic>.from(
          historySnapshot.value as Map,
        );

        List<Map<String, dynamic>> history = [];

        historyData.forEach((key, value) {
          if (value is Map) {
            final transaction = Map<String, dynamic>.from(value as Map);
            // Add the key as transaction ID
            transaction['id'] = key;
            history.add(transaction);
          }
        });

        // Sort by timestamp (newest first)
        history.sort((a, b) {
          final aTimestamp = a['timestamp'] as String? ?? '';
          final bTimestamp = b['timestamp'] as String? ?? '';
          return bTimestamp.compareTo(aTimestamp);
        });

        transactionHistory = history;
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load wallet data: $e';
      });
    }
  }

  // Helper to format credit amount
  String formatCredits(double amount) {
    return amount.toStringAsFixed(0);
  }

  // Helper to format date
  String formatDate(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: responsive.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: responsive.mainSpacing * 0.2),
              // Header with back button, title and refresh button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  // Title
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'My Wallet',
                        style: TextStyle(
                          fontSize: responsive.titleSize * 1.1,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Manrope',
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  // Refresh button
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppColors.primary),
                    onPressed: loadWalletData,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: responsive.mainSpacing * 2),

              // Main content
              if (isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (errorMessage.isNotEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          errorMessage,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textHint,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: loadWalletData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          child: const Text(
                            'Try Again',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Credit Balance Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primary,
                                AppColors.primaryDark,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Credits',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    formatCredits(creditBalance),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'credits',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Earn credits by reporting traffic issues',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Transaction History Title
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Transaction History',
                              style: TextStyle(
                                fontSize: responsive.subtitleSize,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${transactionHistory.length} Transactions',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Transaction History List
                        if (transactionHistory.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.receipt_long,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No transactions yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Report traffic issues to earn credits',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.separated(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: transactionHistory.length,
                            separatorBuilder:
                                (context, index) => const Divider(),
                            itemBuilder: (context, index) {
                              final transaction = transactionHistory[index];
                              final type =
                                  transaction['type'] as String? ?? 'unknown';
                              final amount =
                                  (transaction['amount'] as num?)?.toDouble() ??
                                  0.0;
                              final description =
                                  transaction['description'] as String? ?? '';
                              final timestamp =
                                  transaction['timestamp'] as String? ?? '';

                              // Determine icon and color based on transaction type
                              IconData icon;
                              Color color;

                              switch (type) {
                                case 'credit':
                                  icon = Icons.add_circle_outline;
                                  color = Colors.green;
                                  break;
                                case 'debit':
                                  icon = Icons.remove_circle_outline;
                                  color = Colors.red;
                                  break;
                                default:
                                  icon = Icons.swap_horiz;
                                  color = Colors.blue;
                              }

                              return ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(icon, color: color, size: 24),
                                ),
                                title: Text(
                                  description,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  formatDate(timestamp),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textHint,
                                  ),
                                ),
                                trailing: Text(
                                  '${type == 'credit' ? '+' : '-'}${formatCredits(amount)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        type == 'credit'
                                            ? Colors.green
                                            : Colors.red,
                                  ),
                                ),
                              );
                            },
                          ),

                        // Add space at the bottom for navigation
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
