import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const DocsyApp());

class DocsyApp extends StatefulWidget {
  const DocsyApp({super.key});
  @override State<DocsyApp> createState() => _DocsyAppState();
}
class _DocsyAppState extends State<DocsyApp> {
  static const _languageKey = 'docsy_language_fa_v1';
  static const _themeKey = 'docsy_dark_theme_v1';
  ThemeMode mode = ThemeMode.light;
  bool fa = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      fa = prefs.getBool(_languageKey) ?? true;
      mode = (prefs.getBool(_themeKey) ?? false) ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> _toggleLanguage() async {
    setState(() => fa = !fa);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_languageKey, fa);
  }

  Future<void> _toggleTheme() async {
    setState(() => mode = mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, mode == ThemeMode.dark);
  }

  @override Widget build(BuildContext context) {
    const accent = Color(0xFFFF8A3D);
    ThemeData makeTheme(bool dark) => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: accent, brightness: dark ? Brightness.dark : Brightness.light),
      scaffoldBackgroundColor: dark ? const Color(0xFF111111) : const Color(0xFFF7F7F5),
      appBarTheme: AppBarTheme(backgroundColor: dark ? const Color(0xFF111111) : const Color(0xFFF7F7F5), elevation: 0),
      cardColor: dark ? const Color(0xFF1D1D1D) : Colors.white,
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: dark ? const Color(0xFF262626) : const Color(0xFFECECE9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false, title: 'Docsy', theme: makeTheme(false), darkTheme: makeTheme(true), themeMode: mode,
      locale: Locale(fa ? 'fa' : 'en'), supportedLocales: const [Locale('fa'), Locale('en')],
      localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      home: DocsyHome(fa: fa, dark: mode == ThemeMode.dark,
        toggleLanguage: _toggleLanguage,
        toggleTheme: _toggleTheme),
    );
  }
}

class DocFile {
  const DocFile(this.path, this.name, this.ext, this.added);
  final String path, name, ext;
  final int added;
  Map<String,dynamic> toJson() => {'path':path,'name':name,'ext':ext,'added':added};
  factory DocFile.fromJson(Map<String,dynamic> j) => DocFile(j['path'] as String? ?? '', j['name'] as String? ?? 'Document', j['ext'] as String? ?? '', j['added'] as int? ?? 0);
}

class DocsyHome extends StatefulWidget {
  const DocsyHome({super.key, required this.fa, required this.dark, required this.toggleLanguage, required this.toggleTheme});
  final bool fa, dark;
  final VoidCallback toggleLanguage, toggleTheme;
  @override State<DocsyHome> createState() => _DocsyHomeState();
}
class _DocsyHomeState extends State<DocsyHome> {
  static const storageKey = 'docsy_recent_v1';
  final search = TextEditingController();
  List<DocFile> files = [];
  String query = '', filter = 'all';
  bool loading = true;
  bool get fa => widget.fa;
  String t(String f, String e) => fa ? f : e;
  static const extensions = ['pdf','doc','docx','xls','xlsx','ppt','pptx','txt','rtf','csv','odt','ods','odp'];

  @override void initState() { super.initState(); loadFiles(); }
  @override void dispose() { search.dispose(); super.dispose(); }
  Future<void> loadFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw != null) {
      try {
        final restored = (jsonDecode(raw) as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map(DocFile.fromJson)
            .where((file) => file.path.isNotEmpty)
            .toList();
        // Drop stale entries rather than leaving files that can never open.
        // The source files themselves are never deleted here.
        files = restored.where((file) {
          try {
            return File(file.path).existsSync();
          } catch (_) {
            return false;
          }
        }).toList();
        if (files.length != restored.length) {
          await prefs.setString(
            storageKey,
            jsonEncode(files.map((file) => file.toJson()).toList()),
          );
        }
      } catch (_) {
        await prefs.remove(storageKey);
        files = [];
      }
    }
    if (mounted) setState(() => loading = false);
  }
  Future<void> saveFiles() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(files.map((f) => f.toJson()).toList()));
  }

  Future<void> removeFile(DocFile file) async {
    setState(() => files.removeWhere((item) => item.path == file.path));
    await saveFiles();

    // Only delete files that Docsy itself copied into its private library.
    // Older entries may point to the user's original documents.
    try {
      final appDirectory = await getApplicationDocumentsDirectory();
      final managedDirectory = p.normalize(p.join(appDirectory.path, 'documents'));
      final candidate = p.normalize(file.path);
      if (p.isWithin(managedDirectory, candidate) &&
          await File(candidate).exists()) {
        await File(candidate).delete();
      }
    } catch (_) {
      // The library entry is removed even if private-file cleanup fails.
    }
    message(t('از کتابخانه حذف شد.','Removed from your library.'));
  }

  void message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
  }
  Future<void> pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: extensions,
        allowMultiple: true,
        withData: false,
        withReadStream: true,
      );
      if (result == null) return;

      // Keep an app-owned copy instead of depending on a temporary picker path
      // or a content URI whose access may expire after the picker closes.
      final appDirectory = await getApplicationDocumentsDirectory();
      final libraryDirectory = Directory(p.join(appDirectory.path, 'documents'));
      await libraryDirectory.create(recursive: true);

      final picked = <DocFile>[];
      var failed = 0;
      for (var i = 0; i < result.files.length; i++) {
        final file = result.files[i];
        final name = p.basename(file.name);
        final stamp = DateTime.now().microsecondsSinceEpoch;
        final destination = File(p.join(libraryDirectory.path, '${stamp}_${i}_$name'));
        try {
          final sourcePath = file.path;
          if (sourcePath != null && await File(sourcePath).exists()) {
            await File(sourcePath).copy(destination.path);
          } else if (file.readStream != null) {
            final sink = destination.openWrite();
            try {
              await for (final chunk in file.readStream!) {
                sink.add(chunk);
              }
              await sink.flush();
            } finally {
              await sink.close();
            }
          } else if (file.bytes != null) {
            await destination.writeAsBytes(file.bytes!, flush: true);
          } else {
            failed++;
            continue;
          }

          picked.add(DocFile(
            destination.path,
            name,
            p.extension(name).replaceFirst('.', '').toLowerCase(),
            DateTime.now().millisecondsSinceEpoch,
          ));
        } catch (error, stackTrace) {
          debugPrint('Docsy: failed to copy picked file "${file.name}": $error');
          debugPrintStack(stackTrace: stackTrace);
          failed++;
          if (await destination.exists()) {
            await destination.delete();
          }
        }
      }

      if (picked.isEmpty) {
        message(t(
          'خواندن فایل انتخاب‌شده ممکن نشد. دوباره انتخابش کن.',
          'Could not read the selected file. Please choose it again.',
        ));
        return;
      }

      setState(() {
        for (final file in picked.reversed) {
          files.removeWhere((old) => old.path == file.path);
          files.insert(0, file);
        }
      });
      await saveFiles();

      if (picked.length == 1) {
        await openFile(picked.first);
      } else {
        message(failed > 0
            ? t('${picked.length} فایل اضافه شد؛ $failed فایل خوانده نشد.',
                '${picked.length} files added; $failed could not be read.')
            : t('فایل‌ها به کتابخانه اضافه شدند.', 'Files added to your library.'));
      }
    } catch (error, stackTrace) {
      debugPrint('Docsy: file picker flow failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      message(t(
        'انتخاب فایل انجام نشد. دوباره تلاش کن؛ اگر مشکل ادامه داشت، فایل دیگری را امتحان کن.',
        'File selection failed. Please try again, or choose a different file if the issue persists.',
      ));
    }
  }
  Future<void> openFile(DocFile f) async {
    try {
      if (!await File(f.path).exists()) { message(t('فایل پیدا نشد؛ دوباره انتخابش کن.','File not found. Please select it again.')); return; }
      if (!mounted) return;
      if (f.ext == 'pdf') {
        await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => PdfReaderScreen(path: f.path, title: f.name, fa: fa),
        ));
        return;
      }
      if (['txt', 'csv'].contains(f.ext)) {
        final source = File(f.path);
        final sourceLength = await source.length();
        if (!mounted) return;
        if (sourceLength <= 2 * 1024 * 1024) {
          final text = await source.readAsString();
          if (!mounted) return;
          await showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: SelectableText(text, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.45)),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(t('بستن', 'Close')),
                ),
              ],
            ),
          );
          return;
        }
      }
      final result = await OpenFilex.open(f.path);
      if (result.type != ResultType.done) {
        final details = result.message.trim();
        message(details.isNotEmpty
            ? t('بازکردن فایل ممکن نشد: $details',
                'Could not open file: $details')
            : t('برنامه سازگار برای بازکردن این فایل پیدا نشد.',
                'No compatible app was found to open this file.'));
      }
    } catch (_) {
      message(t(
        'بازکردن فایل ناموفق بود. فایل را بررسی کن و دوباره تلاش کن.',
        'Could not open the file. Check the file and try again.',
      ));
    }
  }
  Color fileColor(String e) {
    if (e == 'pdf') return const Color(0xFFE45B55);
    if (['doc','docx','odt','rtf','txt'].contains(e)) return const Color(0xFF4D86E8);
    if (['xls','xlsx','csv','ods'].contains(e)) return const Color(0xFF35A875);
    if (['ppt','pptx','odp'].contains(e)) return const Color(0xFFE58B45);
    return const Color(0xFF8A78D8);
  }
  IconData fileIcon(String e) {
    if (e == 'pdf') return Icons.picture_as_pdf_rounded;
    if (['doc','docx','odt','rtf','txt'].contains(e)) return Icons.article_rounded;
    if (['xls','xlsx','csv','ods'].contains(e)) return Icons.grid_on_rounded;
    if (['ppt','pptx','odp'].contains(e)) return Icons.slideshow_rounded;
    return Icons.description_rounded;
  }
  List<DocFile> get visibleFiles => files.where((f) {
    final q = f.name.toLowerCase().contains(query.toLowerCase());
    final match = switch (filter) {
      'pdf' => f.ext == 'pdf',
      'word' => ['doc','docx','odt','rtf','txt'].contains(f.ext),
      'sheet' => ['xls','xlsx','csv','ods'].contains(f.ext),
      'slides' => ['ppt','pptx','odp'].contains(f.ext),
      _ => true,
    };
    return q && match;
  }).toList();
  int count(List<String> e) => files.where((f) => e.contains(f.ext)).length;

  @override Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = widget.dark ? Colors.white60 : Colors.black54;
    final docs = visibleFiles;
    return Directionality(
      textDirection: fa ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(titleSpacing: 20, title: Row(children: [
          Container(width:38,height:38,decoration:BoxDecoration(color:widget.dark?Colors.white:const Color(0xFF171717),borderRadius:BorderRadius.circular(12)),
            child:Icon(Icons.description_rounded,color:widget.dark?Colors.black:Colors.white,size:22)),
          const SizedBox(width:10), const Text('docsy',style:TextStyle(fontWeight:FontWeight.w900,letterSpacing:-.8)),
        ]), actions: [
          IconButton(onPressed:widget.toggleLanguage,tooltip:t('تغییر زبان','Change language'),icon:const Icon(Icons.translate_rounded)),
          IconButton(onPressed:widget.toggleTheme,tooltip:t('تغییر تم','Toggle theme'),icon:Icon(widget.dark?Icons.light_mode_rounded:Icons.dark_mode_rounded)),
          const SizedBox(width:8),
        ]),
        floatingActionButton: FloatingActionButton.extended(onPressed:pickFiles,
          backgroundColor:widget.dark?Colors.white:const Color(0xFF171717),foregroundColor:widget.dark?Colors.black:Colors.white,
          icon:const Icon(Icons.add_rounded),label:Text(t('افزودن فایل','Add files'),style:const TextStyle(fontWeight:FontWeight.w700))),
        body: SafeArea(child: RefreshIndicator(onRefresh:loadFiles,child:ListView(padding:const EdgeInsets.fromLTRB(20,12,20,32),children:[
          Text(t('همه اسنادت،\nیک‌جا و مرتب.','Every document,\nin one place.'),style:theme.textTheme.headlineMedium?.copyWith(fontWeight:FontWeight.w900,height:1.12,letterSpacing:-1.1)),
          const SizedBox(height:10), Text(t('فضایی ساده برای فایل‌های روزمره‌ات.','A calmer way to access your everyday files.'),style:theme.textTheme.bodyMedium?.copyWith(color:muted)),
          const SizedBox(height:22),
          Material(color:widget.dark?const Color(0xFF242424):const Color(0xFF171717),borderRadius:BorderRadius.circular(24),
            child:InkWell(onTap:pickFiles,borderRadius:BorderRadius.circular(24),child:Padding(padding:const EdgeInsets.all(20),child:Row(children:[
              Container(width:54,height:62,decoration:BoxDecoration(color:Colors.white.withValues(alpha: .09),borderRadius:BorderRadius.circular(15)),child:const Icon(Icons.drive_folder_upload_rounded,color:Color(0xFFFFA56D),size:28)),
              const SizedBox(width:15),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text(t('فایل جدید باز کن','Open a new file'),style:const TextStyle(color:Colors.white,fontSize:17,fontWeight:FontWeight.w800)),
                const SizedBox(height:5),Text(t('PDF، Word، Excel و بیشتر','PDF, Word, Excel & more'),style:TextStyle(color:Colors.white.withValues(alpha: .65),fontSize:12)),
              ])),const Icon(Icons.arrow_forward_rounded,color:Colors.white),
            ])))),
          const SizedBox(height:24), Row(children:[
            Expanded(child:Text(t('کتابخانه','Your library'),style:theme.textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w900))),
            Text('${files.length} ${t('فایل','files')}',style:theme.textTheme.bodySmall?.copyWith(color:muted)),
          ]),
          const SizedBox(height:14), TextField(controller:search,onChanged:(v)=>setState(()=>query=v),
            decoration:InputDecoration(hintText:t('جست‌وجوی نام فایل...','Search documents...'),prefixIcon:const Icon(Icons.search_rounded),
              suffixIcon:query.isEmpty?null:IconButton(onPressed:(){search.clear();setState(()=>query='');},icon:const Icon(Icons.close_rounded)))),
          const SizedBox(height:13), SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[
            for(final entry in <String,String>{'all':t('همه','All'),'pdf':'PDF','word':t('متن','Text'),'sheet':t('جدول','Sheets'),'slides':t('ارائه','Slides')}.entries)
              Padding(padding:const EdgeInsetsDirectional.only(end:8),child:ChoiceChip(label:Text(entry.value),selected:filter==entry.key,showCheckmark:false,side:BorderSide.none,
                onSelected:(_)=>setState(()=>filter=entry.key),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12)))),
          ])),
          const SizedBox(height:16),
          if(loading) const Padding(padding:EdgeInsets.all(32),child:Center(child:CircularProgressIndicator()))
          else if(docs.isEmpty) emptyState()
          else for(final f in docs) Padding(padding:const EdgeInsets.only(bottom:10),child:documentRow(f,muted)),
          const SizedBox(height:14), Row(children:[
            Expanded(child:statCard('PDF',count(['pdf']),Icons.picture_as_pdf_rounded,const Color(0xFFE45B55))),
            const SizedBox(width:10),Expanded(child:statCard(t('متنی','Text'),count(['doc','docx','odt','rtf','txt']),Icons.article_rounded,const Color(0xFF4D86E8))),
            const SizedBox(width:10),Expanded(child:statCard(t('جدولی','Sheets'),count(['xls','xlsx','csv','ods']),Icons.grid_on_rounded,const Color(0xFF35A875))),
          ]),
          const SizedBox(height:24),Center(child:Text(t('ساخته‌شده برای سادگی.','Made for clarity.'),style:theme.textTheme.labelSmall?.copyWith(color:muted))),
        ]))),
      ),
    );
  }
  Widget documentRow(DocFile f, Color muted) {
    final c=fileColor(f.ext);
    return Material(color:Theme.of(context).cardColor,borderRadius:BorderRadius.circular(18),child:InkWell(onTap:()=>openFile(f),borderRadius:BorderRadius.circular(18),
      child:Padding(padding:const EdgeInsets.all(13),child:Row(children:[
        Container(width:48,height:52,decoration:BoxDecoration(color:c.withValues(alpha: .12),borderRadius:BorderRadius.circular(14)),child:Icon(fileIcon(f.ext),color:c,size:25)),
        const SizedBox(width:13),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(f.name,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w800)),
          const SizedBox(height:5),Text(f.ext.toUpperCase(),style:TextStyle(color:muted,fontSize:11,letterSpacing:.8,fontWeight:FontWeight.w600)),
        ])),
        IconButton(
          tooltip: t('حذف از کتابخانه', 'Remove from library'),
          onPressed: () => removeFile(f),
          icon: Icon(Icons.close_rounded, color: muted, size: 19),
        ),
      ]))));
  }
  Widget emptyState() => Container(padding:const EdgeInsets.symmetric(horizontal:22,vertical:30),
    decoration:BoxDecoration(color:Theme.of(context).cardColor,borderRadius:BorderRadius.circular(22)),
    child:Column(children:[
      Container(width:62,height:62,decoration:BoxDecoration(color:const Color(0xFFFF8A3D).withValues(alpha: .13),shape:BoxShape.circle),
        child:const Icon(Icons.folder_open_rounded,size:29,color:Color(0xFFFF8A3D))),
      const SizedBox(height:14),Text(t('هنوز فایلی اینجا نیست','Nothing here yet'),style:const TextStyle(fontWeight:FontWeight.w900,fontSize:16)),
      const SizedBox(height:7),Text(t('اولین سندت را انتخاب کن تا اینجا نمایش داده شود.','Choose your first document and it will appear here.'),
        textAlign:TextAlign.center,style:TextStyle(color:widget.dark?Colors.white60:Colors.black54,height:1.5,fontSize:12)),
      const SizedBox(height:16),OutlinedButton.icon(onPressed:pickFiles,icon:const Icon(Icons.add_rounded),label:Text(t('انتخاب فایل','Choose a file'))),
    ]));
  Widget statCard(String title,int value,IconData icon,Color color) => Container(padding:const EdgeInsets.all(13),
    decoration:BoxDecoration(color:Theme.of(context).cardColor,borderRadius:BorderRadius.circular(18)),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Icon(icon,color:color,size:20),const SizedBox(height:14),
      Text(value.toString().padLeft(2,'0'),style:const TextStyle(fontSize:21,fontWeight:FontWeight.w900)),
      const SizedBox(height:3),Text(title,maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:11,color:widget.dark?Colors.white60:Colors.black54)),
    ]));

}

class PdfReaderScreen extends StatelessWidget {
  const PdfReaderScreen({super.key, required this.path, required this.title, required this.fa});
  final String path;
  final String title;
  final bool fa;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: fa ? 'بازکردن با برنامه دیگر' : 'Open with another app',
            onPressed: () => OpenFilex.open(path),
            icon: const Icon(Icons.open_in_new_rounded),
          ),
        ],
      ),
      body: PdfViewer.file(
        path,
        params: PdfViewerParams(
          backgroundColor: dark ? const Color(0xFF111111) : const Color(0xFFF0F0EE),
          loadingBannerBuilder: (context, bytesDownloaded, totalBytes) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(fa ? 'در حال بارگذاری سند…' : 'Loading document…'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
