import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../theme/design_a.dart';
import 'login_screen.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _bills = [];
  List<dynamic> _patients = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final responses = await Future.wait([
        ApiService.authorizedGet('/billing/all'),
        ApiService.authorizedGet('/patients/all'),
      ]);

      if (responses.any((r) => r.statusCode == 401 || r.statusCode == 403)) {
        await ApiService.logout();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        return;
      }

      if (responses[0].statusCode != 200 || responses[1].statusCode != 200) {
        setState(() {
          _error = 'Could not load billing information.';
          _isLoading = false;
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _bills = jsonDecode(responses[0].body) as List<dynamic>;
        _patients = jsonDecode(responses[1].body) as List<dynamic>;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not reach the server.';
        _isLoading = false;
      });
    }
  }

  String _money(dynamic value) {
    final amount = value is num ? value.toDouble() : double.tryParse('$value');
    return amount == null ? 'R$value' : 'R${amount.toStringAsFixed(2)}';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'partially_paid':
        return 'Partially paid';
      case 'paid':
        return 'Paid';
      default:
        return 'Unpaid';
    }
  }

  (Color, Color) _statusColours(String status) {
    switch (status) {
      case 'paid':
        return (DA.approvedBg, DA.approvedInk);
      case 'partially_paid':
        return (DA.pendingBg, DA.pendingInk);
      default:
        return (DA.rejectedBg, DA.rejectedInk);
    }
  }

  Future<void> _showBillDialog({Map<String, dynamic>? bill}) async {
    if (_patients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create a patient before adding a bill.')),
      );
      return;
    }

    final descriptionController = TextEditingController(
      text: bill?['description']?.toString() ?? '',
    );
    final amountController = TextEditingController(
      text: bill?['amount']?.toString() ?? '',
    );

    int? patientId = bill?['patient_id'] as int?;
    String status = bill?['status'] as String? ?? 'unpaid';
    DateTime? dueDate = bill?['due_date'] == null
        ? null
        : DateTime.tryParse(bill!['due_date'].toString());
    bool saving = false;
    String? dialogError;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> save() async {
              final amount = double.tryParse(amountController.text.trim());
              if (patientId == null) {
                setDialogState(() => dialogError = 'Select a patient.');
                return;
              }
              if (descriptionController.text.trim().isEmpty) {
                setDialogState(() => dialogError = 'Enter a description.');
                return;
              }
              if (amount == null || amount < 0) {
                setDialogState(() => dialogError = 'Enter a valid amount.');
                return;
              }

              setDialogState(() {
                saving = true;
                dialogError = null;
              });

              final mm = dueDate?.month.toString().padLeft(2, '0');
              final dd = dueDate?.day.toString().padLeft(2, '0');
              final due = dueDate == null ? null : '${dueDate!.year}-$mm-$dd';

              final body = <String, dynamic>{
                if (bill == null) 'patient_id': patientId,
                'description': descriptionController.text.trim(),
                'amount': amount,
                'due_date': due,
                'status': status,
              };

              try {
                final response = bill == null
                    ? await ApiService.authorizedPost('/billing', body)
                    : await ApiService.authorizedPut(
                        '/billing/${bill['id']}',
                        body,
                      );

                if (!context.mounted) return;

                if (response.statusCode >= 200 && response.statusCode < 300) {
                  Navigator.pop(dialogContext);
                  await _load();
                  if (!mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text(
                        bill == null ? 'Bill created.' : 'Bill updated.',
                      ),
                    ),
                  );
                  return;
                }

                final decoded = jsonDecode(response.body);
                final detail = decoded is Map ? decoded['detail'] : null;
                setDialogState(() {
                  saving = false;
                  dialogError = detail is String
                      ? detail
                      : 'Could not save the bill.';
                });
              } catch (_) {
                setDialogState(() {
                  saving = false;
                  dialogError = 'Could not reach the server.';
                });
              }
            }

            return AlertDialog(
              backgroundColor: DA.ground,
              title: Text(
                bill == null ? 'Create bill' : 'Edit bill',
                style: DA.heading(22),
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DA.label('Patient'),
                      DropdownButtonFormField<int>(
                        initialValue: patientId,
                        decoration: DA.input(),
                        hint: Text(
                          'Select patient',
                          style: DA.body(15, color: DA.quiet),
                        ),
                        items: _patients.map((item) {
                          final p = item as Map<String, dynamic>;
                          final name =
                              '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'
                                  .trim();
                          return DropdownMenuItem<int>(
                            value: p['id'] as int,
                            child: Text(name),
                          );
                        }).toList(),
                        onChanged: bill == null && !saving
                            ? (value) => setDialogState(() => patientId = value)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      DA.label('Description'),
                      TextField(
                        controller: descriptionController,
                        enabled: !saving,
                        style: DA.body(16),
                        decoration: DA.input(hint: 'e.g. Consultation'),
                      ),
                      const SizedBox(height: 16),
                      DA.label('Amount (R)'),
                      TextField(
                        controller: amountController,
                        enabled: !saving,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          TextInputFormatter.withFunction((oldValue, newValue) {
                            final validAmount = RegExp(
                              r'^\d*\.?\d{0,2}$',
                            ).hasMatch(newValue.text);

                            return validAmount ? newValue : oldValue;
                          }),
                        ],
                        style: DA.body(16),
                        decoration: DA.input(hint: '0.00'),
                      ),
                      const SizedBox(height: 16),
                      DA.label('Due date'),
                      OutlinedButton(
                        style: DA.outline(),
                        onPressed: saving
                            ? null
                            : () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: dueDate ?? DateTime.now(),
                                  firstDate: DateTime.now().subtract(
                                    const Duration(days: 365),
                                  ),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 3650),
                                  ),
                                );
                                if (picked != null) {
                                  setDialogState(() => dueDate = picked);
                                }
                              },
                        child: Text(
                          dueDate == null
                              ? 'Select due date'
                              : '${dueDate!.day.toString().padLeft(2, '0')}/'
                                    '${dueDate!.month.toString().padLeft(2, '0')}/'
                                    '${dueDate!.year}',
                        ),
                      ),
                      const SizedBox(height: 16),
                      DA.label('Status'),
                      DropdownButtonFormField<String>(
                        initialValue: status,
                        decoration: DA.input(),
                        items: const [
                          DropdownMenuItem(
                            value: 'unpaid',
                            child: Text('Unpaid'),
                          ),
                          DropdownMenuItem(
                            value: 'partially_paid',
                            child: Text('Partially paid'),
                          ),
                          DropdownMenuItem(value: 'paid', child: Text('Paid')),
                        ],
                        onChanged: saving
                            ? null
                            : (value) {
                                if (value != null) {
                                  setDialogState(() => status = value);
                                }
                              },
                      ),
                      if (dialogError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          dialogError!,
                          style: DA.body(14, color: DA.rejectedInk),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DA.rose,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: saving ? null : save,
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    descriptionController.dispose();
    amountController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DA.ground,
      appBar: DA.adminBar('Billing'),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: DA.rose,
        foregroundColor: Colors.white,
        onPressed: _isLoading ? null : () => _showBillDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create bill'),
      ),
      body: RefreshIndicator(
        color: DA.rose,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 96),
          children: [
            DA.page(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Patient billing', style: DA.heading(30)),
                  const SizedBox(height: 6),
                  Text(
                    'Create bills and keep payment status up to date.',
                    style: DA.body(16, color: DA.muted),
                  ),
                  const SizedBox(height: 24),
                  _buildBody(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator(color: DA.rose)),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: DA.card(),
        child: Column(
          children: [
            Text(
              _error!,
              style: DA.body(15, color: DA.rejectedInk),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              style: DA.outline(),
              onPressed: _load,
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    if (_bills.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: DA.card(),
        child: Text(
          'No bills yet. Use Create bill to add the first one.',
          textAlign: TextAlign.center,
          style: DA.body(16, color: DA.muted),
        ),
      );
    }

    return Column(
      children: _bills.map((item) {
        final bill = item as Map<String, dynamic>;
        final status = bill['status'] as String? ?? 'unpaid';
        final first = bill['first_name'] as String? ?? '';
        final last = bill['last_name'] as String? ?? '';
        final due = bill['due_date']?.toString();
        final (bg, ink) = _statusColours(status);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: DA.card(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DA.initials(first, last),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$first $last'.trim(),
                      style: DA.body(16, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      bill['description'] as String? ?? 'Practice bill',
                      style: DA.body(15, color: DA.muted),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _money(bill['amount']),
                      style: DA.heading(21, color: DA.sage),
                    ),
                    if (due != null && due.isNotEmpty)
                      Text('Due: $due', style: DA.body(13, color: DA.quiet)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _statusLabel(status),
                      style: DA.body(12, color: ink, weight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _showBillDialog(bill: bill),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
