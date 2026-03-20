import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class AppTable extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;
  final double height;

  const AppTable({
    super.key,
    required this.headers,
    required this.rows,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    final tableRows = rows
        .map(
          (row) => row
              .map(
                (value) => ShadTableCell(
                  child: Text(value),
                ),
              )
              .toList(),
        )
        .toList();

    return SizedBox(
      height: height,
      child: ShadTable.list(
        header: headers
            .map(
              (header) => ShadTableCell.header(
                child: Text(header),
              ),
            )
            .toList(),
        children: tableRows,
      ),
    );
  }
}