module vcookie

import net.http
import strconv

pub struct Cookie {
  domain              string
  include_subdomains  bool
  path                string
  https_only          bool
  expiry              i64
  name                string
  value               string
}

pub fn parse(file string) ![]Cookie {
  mut cookies := []Cookie{}
  lines := file.split_into_lines()

  for line in lines {
    if line.len == 0 || line.starts_with('#') {
      continue
    }

    parts := line.split_nth('\t', 7)

    if parts.len < 7 {
      return error('invalid cookie line: ${line}')
    }

    cookies << Cookie{
      domain: parts[0]
      include_subdomains: to_bool(parts[1]) or {
        return err
      }
      path: parts[2]
      https_only: to_bool(parts[3]) or {
        return err
      }
      expiry: strconv.atoi64(parts[4]) or {
        return error('invalid expiry: ${parts[4]}')
      }
      name: parts[5]
      value: parts[6]
    }
  }

  return cookies
}

pub fn emit(cookies []Cookie) !string {
  mut file := ''

  for cookie in cookies {
    file += '${cookie.domain}\t${cookie.include_subdomains.str().to_upper()}\t${cookie.path}\t${cookie.https_only.str().to_upper()}\t${cookie.expiry}\t${cookie.name}\t${cookie.value}\n'
  }

  return file
}

pub fn (mut cookies []Cookie) to_map() map[string]string {
  mut cookies_map := map[string]string{}

  for cookie in cookies {
    cookies_map[cookie.name] = cookie.value
  }

  return cookies_map
}

pub fn from_net_cookies(net_cookies []http.Cookie) ![]Cookie {
  mut cookies := []Cookie{}

  for net_cookie in net_cookies {
    cookies << Cookie{
      domain: net_cookie.domain
      include_subdomains: false // not provided by net.http
      path: net_cookie.path
      https_only: net_cookie.secure
      expiry: net_cookie.expires.unix()
      name: net_cookie.name
      value: net_cookie.value
    }
  }

  return cookies
}

fn to_bool(s string) !bool {
  return match s {
    'TRUE' { true }
    'FALSE' { false }
    else { error('invalid bool: ${s}') }
  }
}
