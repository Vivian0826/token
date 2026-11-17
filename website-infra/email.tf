resource "aws_route53_record" "apex_txt" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain
  type    = "TXT"
  ttl     = 300
  records = [
    "google-site-verification=j0PF2vyHlz-fwD7RgfPosPvqUUsYKVnM7l742k585Yg",
    "v=spf1 include:_spf.google.com ~all",
  ]
}

resource "aws_route53_record" "apex_mx" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain
  type    = "MX"
  ttl     = 300
  records = ["1 smtp.google.com"]
}

resource "aws_route53_record" "dmarc" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "_dmarc.${var.domain}"
  type    = "TXT"
  ttl     = 300
  records = ["v=DMARC1; p=none;"]
}

resource "aws_route53_record" "dkim_google" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "google._domainkey.${var.domain}"
  type    = "TXT"
  ttl     = 300
  records = ["v=DKIM1;k=rsa;p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEArW4P+mXaE2IfWr3RmwAsTGgUUg6SO2RZ8vr5rcV4AUO5R9mB0qZCgI/cAHLn1X+M2UMaouyg0CV9jDxcbI5CELlwwHeqA0VATGzBdHLWpev3NmNTLwwV7LiHomCQAzT5g6SqOPeQgydxJYdLb/E1u71sm/p65GBCf2GiHvnKcvvXRrEawYVFg6n/lyQMlHZawxC\" \"dn0y9xwdUU+chj2TYINPH0PNXVo4IHFgpHiVy0sysYD2e7FR9RhOzswPaHaKZu6BcLk51Y0CMlGiYyeT5tRWZ7V/0DOQX6f783hacMui4mWLWaJcuUJ4Ngew/oiK2FqBH/D0zFJsd3b3F056+hwIDAQAB"]
}
