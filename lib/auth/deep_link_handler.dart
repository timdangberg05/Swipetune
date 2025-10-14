import 'dart:async';

import 'package:app_links/app_links.dart';

class DeepLinkHandler {


  final _applinks = AppLinks();
  final _codeCompleter = Completer<String>();
  StreamSubscription? _linkSubscription;

  Future<String> waitForAuthorizationCode()async
  {
    final initial = await  _applinks.getInitialAppLink();
    if(initial != null)
    {
      final code = extractCode(initial);
      if(code != null)
      {
        return code;
      }
    }

    _linkSubscription = _applinks.uriLinkStream.listen((uri)
    {
      if(uri != null && _codeCompleter.isCompleted)
      {
        final code = extractCode(uri);
        if(code != null)
        {
          _codeCompleter.complete(code);
        }
      }
    }
    );

    return _codeCompleter.future.timeout
    (Duration(minutes : 5),
    onTimeout: () 
    {throw new Exception('Timout after period');
    },
    );
    }


  String? extractCode(Uri uri) 
  {
    if(uri.scheme == 'SwipeTune' &&  uri.host =='callback')
    {
      final code = uri.queryParameters['code'];
      final error = uri.queryParameters['error'];

      if(error != null)
      {
        throw Exception('Spotify Error: $error');

      }

      if(code != null)
      {
        print('Code gefunden: ${code.substring(0,20)}...');
        return code;
      }
    }
    return null;
  }

  void dispose() 
  {
    _linkSubscription?.cancel();
  }
}
  
