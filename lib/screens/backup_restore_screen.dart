import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/expense_provider.dart';

class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  final _jsonImportController = TextEditingController();
  bool _isProcessing = false;

  Future<void> _exportCsv() async {
    setState(() => _isProcessing = true);
    try {
      final csv = await ref.read(expenseProvider.notifier).exportCsv();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/bao_cao_tai_chinh_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Báo Cáo Thu Chi Tài Chính',
        text: 'File CSV xuất dữ liệu thu chi từ Finance App',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xuất CSV: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _exportJson() async {
    setState(() => _isProcessing = true);
    try {
      final json = await ref.read(expenseProvider.notifier).exportJson();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/finance_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(json);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Bản Sao Lưu Dữ Liệu Finance',
        text: 'Bản sao lưu JSON dự án Finance',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xuất JSON: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showImportJsonDialog() {
    _jsonImportController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nhập Sao Lưu (JSON)'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dán nội dung JSON sao lưu vào bên dưới:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _jsonImportController,
                maxLines: 8,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '{"app": "FinanceApp", "transactions": [...]}',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              final content = _jsonImportController.text.trim();
              if (content.isEmpty) return;
              Navigator.pop(ctx);
              final count = await ref.read(expenseProvider.notifier).importJson(content);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(count > 0 ? 'Đã nhập thành công $count giao dịch!' : 'Nội dung JSON không hợp lệ!'),
                    backgroundColor: count > 0 ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Khôi Phục'),
          ),
        ],
      ),
    );
  }

  void _confirmClearData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác Nhận Xóa Dữ Liệu?'),
        content: const Text(
          'Thao tác này sẽ xóa vĩnh viễn tất cả các giao dịch trong hệ thống. Bạn có chắc chắn không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(expenseProvider.notifier).clearAllData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã xóa toàn bộ dữ liệu giao dịch!'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: const Text('Xóa Tất Cả'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(expenseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sao Lưu & Xuất Dữ Liệu', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stat summary
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(Icons.storage_rounded, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cơ Sở Dữ Liệu Thiết Bị',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hiện có ${state.allExpenses.length} giao dịch được lưu trữ an toàn ngoại tuyến (SQLite).',
                          style: TextStyle(fontSize: 13, color: theme.hintColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Export Section
          Text(
            'Xuất Báo Cáo & Chia Sẻ',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.12)),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(Icons.table_chart_rounded, color: Color(0xFF2E7D32)),
              ),
              title: const Text('Xuất file CSV (Excel)', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Bảng tính chi tiết phục vụ báo cáo và phân tích trên Excel / Sheets'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _isProcessing ? null : _exportCsv,
            ),
          ),
          const SizedBox(height: 10),

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.12)),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE3F2FD),
                child: Icon(Icons.code_rounded, color: Color(0xFF1565C0)),
              ),
              title: const Text('Sao lưu file JSON', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Bản sao lưu đầy đủ cấu trúc để chuyển sang máy khác hoặc khôi phục'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _isProcessing ? null : _exportJson,
            ),
          ),
          const SizedBox(height: 24),

          // Import & Restore Section
          Text(
            'Khôi Phục & Quản Trị',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.12)),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFFF3E0),
                child: Icon(Icons.file_download_rounded, color: Color(0xFFE65100)),
              ),
              title: const Text('Khôi phục từ bản sao lưu JSON', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Nhập lại toàn bộ danh sách giao dịch và hạn mức đã lưu'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _showImportJsonDialog,
            ),
          ),
          const SizedBox(height: 10),

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.red.withValues(alpha: 0.2)),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFFEBEE),
                child: Icon(Icons.delete_forever_rounded, color: Colors.red),
              ),
              title: const Text('Xóa toàn bộ dữ liệu', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
              subtitle: const Text('Reset cơ sở dữ liệu về trạng thái ban đầu'),
              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.red),
              onTap: _confirmClearData,
            ),
          ),
        ],
      ),
    );
  }
}
