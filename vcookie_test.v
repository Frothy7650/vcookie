module vcookie

import net.http
import time

fn test_parse_valid_cookie_lines() {
	input := '.example.com\tTRUE\t/\tFALSE\t1710000000\tsession\tabc123\n.example.com\tFALSE\t/\tTRUE\t1710009999\tuser\tfrothy\n'

	cookies := parse(input) or {
		assert false
		return
	}

	assert cookies.len == 2

	assert cookies[0].domain == '.example.com'
	assert cookies[0].include_subdomains == true
	assert cookies[0].path == '/'
	assert cookies[0].https_only == false
	assert cookies[0].expiry == i64(1710000000)
	assert cookies[0].name == 'session'
	assert cookies[0].value == 'abc123'
}

fn test_parse_skips_comments_and_empty_lines() {
	input := '
# comment
.example.com\tTRUE\t/\tFALSE\t1710000000\tsession\tabc123

# another comment
'

	cookies := parse(input) or {
		assert false
		return
	}

	assert cookies.len == 1
	assert cookies[0].name == 'session'
}

fn test_emit_roundtrip() {
	input := '.example.com\tTRUE\t/\tFALSE\t1710000000\tsession\tabc123\n'

	cookies := parse(input) or {
		assert false
		return
	}

	out := emit(cookies) or {
		assert false
		return
	}

	cookies2 := parse(out) or {
		assert false
		return
	}

	assert cookies2.len == cookies.len
	assert cookies2[0].name == cookies[0].name
	assert cookies2[0].value == cookies[0].value
	assert cookies2[0].domain == cookies[0].domain
}

fn test_to_map_overwrites_duplicate_names() {
	input := '
.example.com\tTRUE\t/\tFALSE\t1710000000\tsession\tabc123
.example.com\tTRUE\t/\tFALSE\t1710000000\tsession\toverride
'

	cookies := parse(input) or {
		assert false
		return
	}

	m := cookies.to_map()

	assert m['session'] == 'override'
}

fn test_from_net_http_cookies() {
	net_cookies := [
		http.Cookie{
			name:    'sid'
			value:   'xyz'
			path:    '/'
			domain:  'example.com'
			secure:  true
			expires: time.now()
		},
	]

	cookies := from_net_cookies(net_cookies) or {
		assert false
		return
	}

	assert cookies.len == 1
	assert cookies[0].name == 'sid'
	assert cookies[0].value == 'xyz'
	assert cookies[0].https_only == true
}
