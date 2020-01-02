import jwt, times, json

var tok = JWT(
    header: JOSEHeader(alg: RS256, typ: "JWT"),
    claims: toClaims(%*{
    "iss": "foo@foo.com",
    "scope": "foo",
    "aud": "https://www.googleapis.com/oauth2/v4/token",
    "exp": int(epochTime() + 60 * 60),
    "iat": int(epochTime())
  }))

echo $(cast[int](addr tok))
echo "done"

tok.sign("0000000000000000000")