import 'dart:typed_data';

import 'package:archive/archive.dart';

// ============================================================================
// Generador de archivos PowerPoint (.pptx)
//
// Genera un archivo PPTX válido a partir de imágenes de diapositivas PNG.
// El resultado se puede abrir en PowerPoint, Google Slides o Keynote.
//
// Extraído de export_service.dart para separar la generación de XML de la
// lógica de renderizado de páginas.
// ============================================================================

/// Genera un archivo .pptx a partir de imágenes de diapositivas.
///
/// Cada imagen se inserta como una diapositiva. El archivo resultante
/// es un ZIP con la estructura XML estándar de PowerPoint.
Uint8List buildPptx(List<Uint8List> slideImages, String title) {
  final archive = Archive();

  // [Content_Types].xml
  archive.addFile(ArchiveFile(
    '[Content_Types].xml',
    _contentTypes(slideImages.length).length,
    _contentTypes(slideImages.length).codeUnits,
  ));

  // _rels/.rels
  final rels = _rels();
  archive.addFile(ArchiveFile('_rels/.rels', rels.length, rels.codeUnits));

  // ppt/presentation.xml
  final presentation = _presentation(slideImages.length);
  archive.addFile(ArchiveFile(
    'ppt/presentation.xml',
    presentation.length,
    presentation.codeUnits,
  ));

  // ppt/_rels/presentation.xml.rels
  final presRels = _presentationRels(slideImages.length);
  archive.addFile(ArchiveFile(
    'ppt/_rels/presentation.xml.rels',
    presRels.length,
    presRels.codeUnits,
  ));

  // ppt/slides/slide1.xml ... slideN.xml + imagenes
  for (var i = 0; i < slideImages.length; i++) {
    final num = i + 1;

    // Slide XML
    final slideXml = _slide(num, slideImages.length);
    archive.addFile(ArchiveFile(
      'ppt/slides/slide$num.xml',
      slideXml.length,
      slideXml.codeUnits,
    ));

    // Slide rels (referencia a la imagen)
    final slideRels = _slideRels(num);
    archive.addFile(ArchiveFile(
      'ppt/slides/_rels/slide$num.xml.rels',
      slideRels.length,
      slideRels.codeUnits,
    ));

    // Imagen PNG
    archive.addFile(ArchiveFile(
      'ppt/media/slide$num.png',
      slideImages[i].length,
      slideImages[i],
    ));
  }

  // ppt/slideLayouts + slideMasters (necesarios para que PPTX sea válido)
  final slideLayout = _slideLayout();
  archive.addFile(ArchiveFile(
    'ppt/slideLayouts/slideLayout1.xml',
    slideLayout.length,
    slideLayout.codeUnits,
  ));
  final slideMaster = _slideMaster();
  archive.addFile(ArchiveFile(
    'ppt/slideMasters/slideMaster1.xml',
    slideMaster.length,
    slideMaster.codeUnits,
  ));

  // Rels de slideLayout y slideMaster
  final layoutRels = _layoutRels();
  archive.addFile(ArchiveFile(
    'ppt/slideLayouts/_rels/slideLayout1.xml.rels',
    layoutRels.length,
    layoutRels.codeUnits,
  ));
  final masterRels = _masterRels();
  archive.addFile(ArchiveFile(
    'ppt/slideMasters/_rels/slideMaster1.xml.rels',
    masterRels.length,
    masterRels.codeUnits,
  ));

  return Uint8List.fromList(ZipEncoder().encode(archive));
}

// ---------------------------------------------------------------------------
// Plantillas XML (privadas)
// ---------------------------------------------------------------------------

String _contentTypes(int slideCount) {
  final overrides = StringBuffer();
  for (var i = 1; i <= slideCount; i++) {
    overrides.writeln(
      '  <Override PartName="/ppt/slides/slide$i.xml" '
      'ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml" />',
    );
  }
  return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">\n'
      '  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml" />\n'
      '  <Default Extension="xml" ContentType="application/xml" />\n'
      '  <Default Extension="png" ContentType="image/png" />\n'
      '  <Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml" />\n'
      '  <Override PartName="/ppt/slideMasters/slideMaster1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideMaster+xml" />\n'
      '  <Override PartName="/ppt/slideLayouts/slideLayout1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideLayout+xml" />\n'
      '$overrides</Types>';
}

String _rels() {
  return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n'
      '  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="ppt/presentation.xml" />\n'
      '</Relationships>';
}

String _presentation(int slideCount) {
  final sldIdLst = StringBuffer();
  for (var i = 0; i < slideCount; i++) {
    sldIdLst.writeln('      <p:sldId id="${256 + i}" r:id="rId${i + 1}" />');
  }
  return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
      '<p:presentation xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" '
      'xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" '
      'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">\n'
      '  <p:sldMasterIdLst>\n'
      '    <p:sldMasterId id="2147483648" r:id="rId${slideCount + 1}" />\n'
      '  </p:sldMasterIdLst>\n'
      '  <p:sldIdLst>\n'
      '$sldIdLst  </p:sldIdLst>\n'
      '  <p:sldSz cx="12192000" cy="6858000" type="screen4x3" />\n'
      '  <p:notesSz cx="6858000" cy="9144000" />\n'
      '</p:presentation>';
}

String _presentationRels(int slideCount) {
  final buf = StringBuffer();
  for (var i = 1; i <= slideCount; i++) {
    buf.writeln(
      '  <Relationship Id="rId$i" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide$i.xml" />',
    );
  }
  buf.writeln(
    '  <Relationship Id="rId${slideCount + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="slideMasters/slideMaster1.xml" />',
  );
  return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n'
      '$buf</Relationships>';
}

String _slide(int num, int total) {
  return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
      '<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" '
      'xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" '
      'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">\n'
      '  <p:cSld>\n'
      '    <p:spTree>\n'
      '      <p:nvGrpSpPr>\n'
      '        <p:cNvPr id="1" name="" />\n'
      '        <p:cNvGrpSpPr />\n'
      '        <p:nvPr />\n'
      '      </p:nvGrpSpPr>\n'
      '      <p:grpSpPr />\n'
      '      <p:pic>\n'
      '        <p:nvPicPr>\n'
      '          <p:cNvPr id="2" name="Image $num" />\n'
      '          <p:cNvPicPr><a:picLocks noChangeAspect="1" /></p:cNvPicPr>\n'
      '          <p:nvPr />\n'
      '        </p:nvPicPr>\n'
      '        <p:blipFill>\n'
      '          <a:blip r:embed="rId1" />\n'
      '          <a:stretch><a:fillRect /></a:stretch>\n'
      '        </p:blipFill>\n'
      '        <p:spPr>\n'
      '          <a:xfrm>\n'
      '            <a:off x="0" y="0" />\n'
      '            <a:ext cx="12192000" cy="6858000" />\n'
      '          </a:xfrm>\n'
      '          <a:prstGeom prst="rect"><a:avLst /></a:prstGeom>\n'
      '        </p:spPr>\n'
      '      </p:pic>\n'
      '    </p:spTree>\n'
      '  </p:cSld>\n'
      '  <p:clrMapOvr />\n'
      '</p:sld>';
}

String _slideRels(int num) {
  return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n'
      '  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="../media/slide$num.png" />\n'
      '  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml" />\n'
      '</Relationships>';
}

String _slideLayout() {
  return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
      '<p:sldLayout xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" '
      'xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" '
      'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" '
      'type="blank">\n'
      '  <p:cSld name="Blank">\n'
      '    <p:spTree><p:nvGrpSpPr><p:cNvPr id="1" name="" /><p:cNvGrpSpPr /><p:nvPr /></p:nvGrpSpPr><p:grpSpPr /></p:spTree>\n'
      '  </p:cSld>\n'
      '  <p:clrMapOvr />\n'
      '</p:sldLayout>';
}

String _slideMaster() {
  return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
      '<p:sldMaster xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" '
      'xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" '
      'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">\n'
      '  <p:cSld><p:bg><p:bgRef idx="1001"><a:schemeClr val="bg1" /></p:bgRef></p:bg><p:spTree><p:nvGrpSpPr><p:cNvPr id="1" name="" /><p:cNvGrpSpPr /><p:nvPr /></p:nvGrpSpPr><p:grpSpPr /></p:spTree></p:cSld>\n'
      '  <p:clrMap bg1="lt1" tx1="dk1" bg2="lt2" tx2="dk2" accent1="accent1" accent2="accent2" accent3="accent3" accent4="accent4" accent5="accent5" accent6="accent6" hlink="hlink" folHlink="folHlink" />\n'
      '  <p:sldLayoutIdLst><p:sldLayoutId id="2147483649" r:id="rId1" /></p:sldLayoutIdLst>\n'
      '</p:sldMaster>';
}

String _layoutRels() {
  return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n'
      '  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="../slideMasters/slideMaster1.xml" />\n'
      '</Relationships>';
}

String _masterRels() {
  return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n'
      '  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml" />\n'
      '</Relationships>';
}
