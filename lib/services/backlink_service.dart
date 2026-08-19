import '../models/document.dart';
import '../models/page.dart';
import '../models/text_item.dart';

/// Información de un backlink encontrado.
class BacklinkInfo {
  final String fromPageId;
  final String fromPageName;
  final int fromPageIndex;
  final String textItemText;

  const BacklinkInfo({
    required this.fromPageId,
    required this.fromPageName,
    required this.fromPageIndex,
    required this.textItemText,
  });
}

/// Servicio de backlinks (enlaces internos) entre páginas.
///
/// Cada [TextItem] puede tener un campo `linkToPageId` que apunta a otra
/// página del mismo cuaderno. Este servicio ayuda a encontrar y gestionar
/// esos enlaces.
class BacklinkService {
  const BacklinkService._();

  /// Encuentra todos los backlinks que apuntan a una página específica.
  static List<BacklinkInfo> findBacklinksToPage(
    Document document,
    String targetPageId,
  ) {
    final results = <BacklinkInfo>[];
    for (var i = 0; i < document.pages.length; i++) {
      final page = document.pages[i];
      for (final ti in page.textItems) {
        if (ti.linkToPageId == targetPageId) {
          results.add(BacklinkInfo(
            fromPageId: page.id,
            fromPageName: page.name,
            fromPageIndex: i,
            textItemText: ti.text,
          ));
        }
      }
    }
    return results;
  }

  /// Cuenta el total de backlinks en un cuaderno.
  static int countBacklinks(Document document) {
    var count = 0;
    for (final page in document.pages) {
      for (final ti in page.textItems) {
        if (ti.linkToPageId != null) count++;
      }
    }
    return count;
  }

  /// Obtiene la página destino de un enlace dado su pageId.
  static Page? resolveLink(Document document, String pageId) {
    for (final page in document.pages) {
      if (page.id == pageId) return page;
    }
    return null;
  }

  /// Obtiene el índice de una página por su id.
  static int? pageIndex(Document document, String pageId) {
    for (var i = 0; i < document.pages.length; i++) {
      if (document.pages[i].id == pageId) return i;
    }
    return null;
  }
}
