SEP = ", "
QUOTE     = "\'"
NEWLINE   = System.getProperty("line.separator")

def record(columns, dataRow) {
    OUT.append("INSERT INTO ")
    if (TABLE == null) OUT.append("MY_TABLE")
    else OUT.append(TABLE.getParent().getName()).append(".").append(TABLE.getName())
    OUT.append(" (")

    columns.eachWithIndex { column, idx ->
        OUT.append(column.name()).append(idx != columns.size() - 1 ? SEP : "")
    }

    OUT.append(") VALUES (")
    columns.eachWithIndex { column, idx ->
        def skipQuote = dataRow.value(column).toString().isNumber() || dataRow.value(column) == null
        def stringValue = FORMATTER.format(dataRow, column)
        if (DIALECT.getFamilyId().isMysql()) stringValue = stringValue.replace("\\", "\\\\")
        OUT.append(skipQuote ? "": QUOTE).append(stringValue.replace(QUOTE, QUOTE + QUOTE))
           .append(skipQuote ? "": QUOTE).append(idx != columns.size() - 1 ? SEP : "")
    }
    OUT.append(");").append(NEWLINE)
}

ROWS.each { row -> record(COLUMNS, row) }
