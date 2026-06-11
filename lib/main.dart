import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const PokemonApp());

class PokemonApp extends StatelessWidget {
  const PokemonApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokédex',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.red, useMaterial3: true),
      home: const PokemonListPage(),
    );
  }
}

// ══════════════════════════════════════════
// COLORES POR TIPO
// ══════════════════════════════════════════
const typeColors = {
  'fire':     Color(0xFFF08030), 'water':    Color(0xFF6890F0),
  'grass':    Color(0xFF78C850), 'electric': Color(0xFFF8D030),
  'psychic':  Color(0xFFF85888), 'ice':      Color(0xFF98D8D8),
  'dragon':   Color(0xFF7038F8), 'dark':     Color(0xFF705848),
  'fairy':    Color(0xFFEE99AC), 'normal':   Color(0xFFA8A878),
  'fighting': Color(0xFFC03028), 'flying':   Color(0xFFA890F0),
  'poison':   Color(0xFFA040A0), 'ground':   Color(0xFFE0C068),
  'rock':     Color(0xFFB8A038), 'bug':      Color(0xFFA8B820),
  'ghost':    Color(0xFF705898), 'steel':    Color(0xFFB8B8D0),
};
Color typeColor(String t) => typeColors[t] ?? Colors.grey;

// ══════════════════════════════════════════
// MODELOS
// ══════════════════════════════════════════
class PokemonListItem {
  final String name;
  final int id;
  PokemonListItem({required this.name, required this.id});

  String get imageUrl =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/'
      'sprites/pokemon/$id.png';
}

class PokemonDetail {
  final int id;
  final String name, imageUrl;
  final int height, weight;
  final List<String> types, abilities, moves;
  final Map<String, int> stats;

  PokemonDetail({
    required this.id, required this.name, required this.imageUrl,
    required this.height, required this.weight,
    required this.types, required this.abilities,
    required this.moves, required this.stats,
  });

  factory PokemonDetail.fromJson(Map<String, dynamic> j) {
    final artwork =
        j['sprites']['other']?['official-artwork']?['front_default'];
    final fallback = j['sprites']['front_default'];
    return PokemonDetail(
      id: j['id'],
      name: j['name'],
      imageUrl: (artwork != null && artwork.toString().isNotEmpty)
          ? artwork : fallback,
      height: j['height'],
      weight: j['weight'],
      types: (j['types'] as List)
          .map((t) => t['type']['name'] as String).toList(),
      abilities: (j['abilities'] as List)
          .map((a) => a['ability']['name'] as String).toList(),
      moves: (j['moves'] as List)
          .take(5)
          .map((m) => m['move']['name'] as String).toList(),
      stats: {
        for (final s in j['stats'] as List)
          s['stat']['name'] as String: s['base_stat'] as int
      },
    );
  }
}

// ══════════════════════════════════════════
// SERVICIOS HTTP
// ══════════════════════════════════════════
Future<List<PokemonListItem>> fetchPage(int offset, {int limit = 5}) async {
  final res = await http.get(
    Uri.parse(
        'https://pokeapi.co/api/v2/pokemon?limit=$limit&offset=$offset'),
  );
  if (res.statusCode != 200) throw Exception('Error al cargar lista');
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  return (data['results'] as List).asMap().entries.map((e) {
    return PokemonListItem(
      name: e.value['name'] as String,
      id: offset + e.key + 1,
    );
  }).toList();
}

Future<PokemonDetail> fetchDetail(String nameOrId) async {
  final res = await http.get(
    Uri.parse(
        'https://pokeapi.co/api/v2/pokemon/${nameOrId.toLowerCase().trim()}'),
  );
  if (res.statusCode == 200) {
    return PokemonDetail.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }
  throw Exception('Pokémon "$nameOrId" no encontrado');
}

// ══════════════════════════════════════════
// LISTA CON INFINITE SCROLL
// ══════════════════════════════════════════
class PokemonListPage extends StatefulWidget {
  const PokemonListPage({super.key});
  @override
  State<PokemonListPage> createState() => _PokemonListPageState();
}

class _PokemonListPageState extends State<PokemonListPage> {
  final List<PokemonListItem> _items = [];
  final _searchCtrl = TextEditingController();
  bool _loading   = false;
  bool _hasMore   = true;
  bool _searching = false;
  int  _offset    = 0;

  static const _pageLimit = 5;
  static const _total     = 151;

  @override
  void initState() {
    super.initState();
    _loadNext();
  }

  Future<void> _loadNext() async {
    if (_loading || !_hasMore || _searching) return;

    setState(() => _loading = true);
    try {
      final page = await fetchPage(_offset, limit: _pageLimit);
      if (!mounted) return;

      _offset += page.length;
      final done = page.length < _pageLimit ||
          (_total > 0 && _offset >= _total);

      setState(() {
        _items.addAll(page);
        if (done) _hasMore = false;
        _loading = false;
      });

      if (!done) {
        await Future.delayed(Duration.zero);
        if (!mounted) return;
        final ctx = context;
        final scrollable = Scrollable.maybeOf(ctx);
        if (scrollable == null ||
            scrollable.position.maxScrollExtent <= 0) {
          _loadNext();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // Modificado para mostrar el resultado de búsqueda en un diálogo o sección
  void _search() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;
    setState(() => _searching = true);
    try {
      final detail = await fetchDetail(query);
      if (!mounted) return;
      
      // En vez de navegar, abrimos un diálogo rápido para no perder la vista principal
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          content: SingleChildScrollView(
            child: _PokemonCardContent(detail: detail),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            )
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('No se encontró "$query"'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    if (_searching || !_hasMore || _loading) return false;
    if (n is ScrollUpdateNotification) {
      final metrics = n.metrics;
      if (metrics.pixels >= metrics.maxScrollExtent - 200) {
        _loadNext();
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pokédex'), centerTitle: true),
      body: Column(children: [
        // Buscador
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o número...',
              prefixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ))
                  : const Icon(Icons.search),
              suffixIcon: ListenableBuilder(
                listenable: _searchCtrl,
                builder: (_, __) => _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          FocusScope.of(context).unfocus();
                        })
                    : const SizedBox.shrink(),
              ),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withOpacity(0.4),
            ),
            onSubmitted: (_) => _search(),
          ),
        ),

        // Lista
        Expanded(
          child: _items.isEmpty && _loading
              ? const Center(child: CircularProgressIndicator())
              : NotificationListener<ScrollNotification>(
                  onNotification: _onScroll,
                  child: ListView.builder(
                    itemCount: _items.length + (_hasMore || _loading ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i == _items.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return _PokemonTile(item: _items[i]);
                    },
                  ),
                ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════
// TILE REDISEÑADO CON EXPANSIONTILE
// ══════════════════════════════════════════
class _PokemonTile extends StatefulWidget {
  final PokemonListItem item;
  const _PokemonTile({required this.item});

  @override
  State<_PokemonTile> createState() => _PokemonTileState();
}

class _PokemonTileState extends State<_PokemonTile> {
  Future<PokemonDetail>? _detailFuture;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias, // Evita que el contenido se salga de los bordes redondeados
      child: ExpansionTile(
        key: PageStorageKey(widget.item.id), // Mantiene el estado al hacer scroll
        leading: Image.network(
          widget.item.imageUrl,
          width: 56, height: 56,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Icon(Icons.catching_pokemon, size: 40),
        ),
        title: Text(
          widget.item.name.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '#${widget.item.id.toString().padLeft(3, '0')}',
          style: TextStyle(color: Colors.grey[600]),
        ),
        // Dispara la petición HTTP solo cuando se expande por primera vez
        onExpansionChanged: (expanded) {
          if (expanded && _detailFuture == null) {
            setState(() {
              _detailFuture = fetchDetail(widget.item.name);
            });
          }
        },
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: FutureBuilder<PokemonDetail>(
              future: _detailFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Error al cargar detalles: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red)),
                  );
                } else if (snapshot.hasData) {
                  // Reutiliza el diseño visual que ya tenías creado
                  return _PokemonCardContent(detail: snapshot.data!);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════
// CONTENIDO DEL DETALLE (EXTRACCION VISUAL)
// ══════════════════════════════════════════
class _PokemonCardContent extends StatelessWidget {
  final PokemonDetail detail;
  const _PokemonCardContent({required this.detail});

  @override
  Widget build(BuildContext context) {
    final p = detail;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Image.network(
            p.imageUrl,
            height: 150,
            errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported, size: 80),
          ),
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Tipos',
          child: Wrap(
            spacing: 8,
            children: p.types.map((t) => Chip(
              label: Text(t, style: const TextStyle(color: Colors.white, fontSize: 12)),
              backgroundColor: typeColor(t),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )).toList(),
          ),
        ),
        _Section(
          title: 'Físico',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _InfoBox(label: 'Altura', value: '${p.height / 10} m'),
              _InfoBox(label: 'Peso',   value: '${p.weight / 10} kg'),
            ],
          ),
        ),
        _Section(
          title: 'Stats base',
          child: Column(
            children: p.stats.entries
                .map((e) => _StatBar(name: e.key, value: e.value))
                .toList(),
          ),
        ),
        _Section(
          title: 'Habilidades',
          child: Wrap(
            spacing: 8,
            children: p.abilities.map((a) => Chip(
              label: Text(a, style: const TextStyle(fontSize: 12)),
              backgroundColor: Colors.grey[200],
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )).toList(),
          ),
        ),
        _Section(
          title: 'Movimientos (primeros 5)',
          child: Wrap(
            spacing: 6, runSpacing: 6,
            children: p.moves.map((m) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.indigo[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.indigo.shade200),
              ),
              child: Text(m, style: TextStyle(color: Colors.indigo[800], fontSize: 12)),
            )).toList(),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════
// WIDGETS AUXILIARES
// ══════════════════════════════════════════
class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Divider(),
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      const SizedBox(height: 6),
      child,
      const SizedBox(height: 4),
    ]);
  }
}

class _InfoBox extends StatelessWidget {
  final String label, value;
  const _InfoBox({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
    ]);
  }
}

class _StatBar extends StatelessWidget {
  final String name;
  final int value;
  const _StatBar({required this.name, required this.value});
  static const _max = 255;
  static const _names = {
    'hp': 'HP',              'attack': 'ATK',
    'defense': 'DEF',        'special-attack': 'SP.ATK',
    'special-defense': 'SP.DEF', 'speed': 'VEL',
  };
  Color get _color {
    if (value >= 100) return Colors.green;
    if (value >= 60)  return Colors.amber.shade700;
    return Colors.red;
  }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        SizedBox(width: 60,
            child: Text(_names[name] ?? name, style: const TextStyle(fontSize: 11))),
        SizedBox(width: 28,
            child: Text('$value',
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / _max,
              minHeight: 6,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(_color),
            ),
          ),
        ),
      ]),
    );
  }
}