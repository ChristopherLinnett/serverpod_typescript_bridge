// Live round trip: the generated TypeScript client against a running
// fixture server. Run by test/live_roundtrip_test.dart, which boots the
// server and generates the client first:
//
//   node roundtrip.mjs <path to the client's dist/index.js> <server url>
//
// Prints one line per check and exits non-zero if any failed.
import assert from 'node:assert/strict';

const [clientEntry, host] = process.argv.slice(2);
const {
  Client,
  AdminProfile,
  AppException,
  Cat,
  Colour,
  Dog,
  Embedding,
  NotFoundException,
  Priority,
  QuotaException,
  ServerpodClientException,
  Settings,
  UserProfile,
} = await import(clientEntry);

const results = [];
// A check that never settles is a failure, not a hang: a stream the client
// fails to end would otherwise stall the whole run.
const CHECK_TIMEOUT_MS = 5000;

async function check(name, fn) {
  let timer;
  const timedOut = new Promise((_, reject) => {
    timer = setTimeout(
      () => reject(new Error(`did not finish within ${CHECK_TIMEOUT_MS} ms`)),
      CHECK_TIMEOUT_MS,
    );
  });
  try {
    await Promise.race([fn(), timedOut]);
    results.push({ name });
  } catch (error) {
    results.push({ name, error });
  } finally {
    clearTimeout(timer);
  }
}

async function collect(iterable) {
  const values = [];
  for await (const value of iterable) values.push(value);
  return values;
}

async function* from(values) {
  for (const value of values) yield value;
}

const when = new Date('2026-03-04T05:06:07.890Z');
const uuid = '550e8400-e29b-41d4-a716-446655440000';
const rex = () => new Dog({ name: 'Rex', breed: 'Collie', goodWithKids: true });
const tom = () => new Cat({ name: 'Tom', livesRemaining: 7, isIndoor: true });
const profile = (overrides = {}) =>
  new UserProfile({
    id: 9,
    displayName: 'Ada',
    rating: 4.5,
    isPublic: true,
    createdAt: when,
    membershipDuration: 3_600_000,
    karma: 99999999999999999999n,
    deviceId: uuid,
    priority: Priority.High,
    favouriteColour: Colour.Green,
    pet: rex(),
    priorityHistory: [Priority.Low, Priority.Normal],
    ...overrides,
  });

const client = new Client(host);
const authed = new Client(host, {
  authKeyProvider: { getAuthHeaderValue: async () => 'Bearer valid-token' },
});
const rejected = new Client(host, {
  authKeyProvider: { getAuthHeaderValue: async () => 'Bearer wrong-token' },
});

// ---- primitives ----------------------------------------------------------
const p = client.primitives;
await check('int', async () => assert.equal(await p.echoInt(42), 42));
await check('negative int', async () => assert.equal(await p.echoInt(-7), -7));
await check('double', async () => assert.equal(await p.echoDouble(1.5), 1.5));
await check('whole double', async () => assert.equal(await p.echoDouble(2), 2));
await check('string', async () =>
  assert.equal(await p.echoString('héllo ✓ "q" \n'), 'héllo ✓ "q" \n'));
await check('empty string', async () => assert.equal(await p.echoString(''), ''));
await check('bool true', async () => assert.equal(await p.echoBool(true), true));
await check('bool false', async () => assert.equal(await p.echoBool(false), false));
await check('DateTime', async () =>
  assert.equal((await p.echoDateTime(when)).getTime(), when.getTime()));
await check('Duration', async () => assert.equal(await p.echoDuration(90_061_001), 90_061_001));
await check('BigInt beyond 64 bits', async () =>
  assert.equal(await p.echoBigInt(123456789012345678901234567890n), 123456789012345678901234567890n));
await check('UuidValue', async () => assert.equal(await p.echoUuid(uuid), uuid));
await check('ByteData', async () =>
  assert.deepEqual([...(await p.echoBytes(new Uint8Array([0, 1, 2, 250, 255])))], [0, 1, 2, 250, 255]));
await check('empty ByteData', async () =>
  assert.equal((await p.echoBytes(new Uint8Array([]))).length, 0));
await check('Uri', async () =>
  assert.equal(await client.params.echoUri('https://example.com/a?b=c#d'), 'https://example.com/a?b=c#d'));

// ---- collections ---------------------------------------------------------
const c = client.collections;
await check('List<int>', async () => assert.deepEqual(await c.echoIntList([3, 1, 2]), [3, 1, 2]));
await check('empty List', async () => assert.deepEqual(await c.echoIntList([]), []));
await check('Set<String>', async () =>
  assert.deepEqual([...(await c.echoStringSet(new Set(['a', 'b'])))].sort(), ['a', 'b']));
await check('Map<String,int>', async () =>
  assert.deepEqual(await c.echoStringIntMap({ a: 1, b: 2 }), { a: 1, b: 2 }));
await check('Map<int,String>', async () =>
  assert.deepEqual([...(await c.echoIntStringMap(new Map([[1, 'x'], [2, 'y']])))], [[1, 'x'], [2, 'y']]));

// ---- nullables -----------------------------------------------------------
const n = client.nullables;
await check('int? null', async () => assert.equal(await n.nullableInt(null), null));
await check('int? value', async () => assert.equal(await n.nullableInt(7), 7));
await check('int? zero', async () => assert.equal(await n.nullableInt(0), 0));
await check('String? null', async () => assert.equal(await n.nullableString(null), null));
await check('List? null', async () => assert.equal(await n.nullableList(null), null));
await check('List? value', async () => assert.deepEqual(await n.nullableList([1]), [1]));
await check('model? null', async () => assert.equal(await n.nullableProfile(null), null));
await check('model? value', async () =>
  assert.deepEqual((await n.nullableProfile(profile())).toJson(), profile().toJson()));

// ---- enums ---------------------------------------------------------------
const e = client.enums;
await check('enum by index', async () => assert.equal(await e.echoPriority(Priority.High), Priority.High));
await check('enum by index, first member', async () =>
  assert.equal(await e.echoPriority(Priority.Low), Priority.Low));
await check('enum by name', async () => assert.equal(await e.echoColour(Colour.Blue), Colour.Blue));
await check('enum? null', async () => assert.equal(await e.echoNullablePriority(null), null));
await check('enum? value', async () =>
  assert.equal(await e.echoNullablePriority(Priority.Normal), Priority.Normal));
await check('List<enum>', async () =>
  assert.deepEqual(await e.echoPriorities([Priority.High, Priority.Low]), [Priority.High, Priority.Low]));
await check('Map<String,enum>', async () =>
  assert.deepEqual(await e.echoColourMap({ a: Colour.Red, b: Colour.Blue }), { a: Colour.Red, b: Colour.Blue }));

// ---- parameters ----------------------------------------------------------
const params = client.params;
await check('named params, optional omitted', async () =>
  assert.equal(await params.named('x', { b: 2 }), 'x|2|none'));
await check('named params, optional given', async () =>
  assert.equal(await params.named('x', { b: 2, c: 'y' }), 'x|2|y'));
await check('optional positional omitted', async () => assert.equal(await params.optional('x'), 'x|none'));
await check('optional positional given', async () => assert.equal(await params.optional('x', 5), 'x|5'));
await check('typed arguments', async () =>
  assert.equal(
    await params.typed(when, 1500, 12345678901234567890n, new Set([3, 1]), new Map([[1, 'a']]), [
      profile({ displayName: 'P1' }),
      profile({ displayName: 'P2' }),
    ]),
    '2026-03-04T05:06:07.890Z|1500|12345678901234567890|1,3|1=a|P1,P2',
  ));

// ---- models --------------------------------------------------------------
const models = client.models;
await check('model round trip', async () => {
  const sent = profile();
  const got = await models.echoProfile(sent);
  assert.ok(got instanceof UserProfile);
  assert.deepEqual(got.toJson(), sent.toJson());
  assert.equal(got.birthYear, null);
  assert.equal(got.bio, null);
  assert.ok(got.pet instanceof Dog, 'a sealed field decodes to its concrete class');
  assert.equal(got.pet.name, 'Rex');
});
await check('model with every nullable set', async () => {
  const sent = profile({ birthYear: 1815, bio: 'First programmer', pet: tom() });
  const got = await models.echoProfile(sent);
  assert.equal(got.birthYear, 1815);
  assert.equal(got.bio, 'First programmer');
  assert.ok(got.pet instanceof Cat);
});
await check('subclass return carries inherited fields', async () => {
  const admin = await models.promoteToAdmin(profile(), 'ops');
  assert.ok(admin instanceof AdminProfile);
  assert.ok(admin instanceof UserProfile, 'a subclass is an instance of its parent');
  assert.equal(admin.scope, 'ops');
  assert.equal(admin.displayName, 'Ada');
  assert.equal(admin.karma, 99999999999999999999n);
});
await check('subclass sent and returned where the parent is declared', async () => {
  const admin = new AdminProfile({ ...profile(), scope: 'root' });
  const got = await params.asParent(admin);
  assert.ok(got instanceof AdminProfile, `got ${got.constructor.name}`);
  assert.equal(got.scope, 'root');
});
await check('sealed dispatch, each subclass with its inherited field', async () => {
  const dog = await models.echoAnimal(rex());
  assert.ok(dog instanceof Dog);
  assert.equal(dog.name, 'Rex');
  assert.equal(dog.breed, 'Collie');
  const cat = await models.echoAnimal(tom());
  assert.ok(cat instanceof Cat);
  assert.equal(cat.name, 'Tom');
  assert.equal(cat.livesRemaining, 7);
});
await check('copyWith keeps, replaces and clears', async () => {
  const base = profile({ bio: 'x' });
  assert.equal(base.copyWith({}).bio, 'x');
  assert.equal(base.copyWith({ bio: 'y' }).bio, 'y');
  assert.equal(base.copyWith({ bio: null }).bio, null);
  assert.equal(base.copyWith({ displayName: 'Z' }).displayName, 'Z');
});
await check('model defaults filled by the client', async () => {
  const settings = new Settings({});
  assert.equal(settings.count, 3);
  assert.equal(settings.label, 'untitled');
  assert.equal(settings.enabled, true);
  assert.equal(settings.mode, Priority.Normal);
  assert.equal(settings.ratio, 1.5);
  assert.equal(settings.note, null);
  assert.deepEqual((await params.echoSettings(settings)).toJson(), settings.toJson());
});
await check('model defaults overridden', async () => {
  const got = await params.echoSettings(new Settings({ count: 0, enabled: false, mode: Priority.High }));
  assert.equal(got.count, 0);
  assert.equal(got.enabled, false);
  assert.equal(got.mode, Priority.High);
  assert.equal(got.label, 'untitled');
});
await check('model defaults filled by the server', async () => {
  const got = await params.defaultSettings();
  assert.equal(got.count, 3);
  assert.equal(got.mode, Priority.Normal);
});
await check('vector and geography values', async () => {
  const sent = new Embedding({
    vec: [1, 2.5, 3],
    half: [0.5, 1, 1.5],
    sparse: '{1:1.5,3:2.0}/3',
    bits: '101',
    point: 'SRID=4326;POINT(153.02 -27.47)',
  });
  const got = await params.echoEmbedding(sent);
  assert.deepEqual(got.vec, [1, 2.5, 3]);
  assert.deepEqual(got.half, [0.5, 1, 1.5]);
  assert.equal(got.sparse, sent.sparse);
  assert.equal(got.bits, '101');
  assert.equal(got.point, sent.point);
});

// ---- exceptions ----------------------------------------------------------
await check('typed exception', async () => {
  await assert.rejects(() => models.findOrThrow(5), (error) => {
    assert.ok(error instanceof NotFoundException, `got ${error?.constructor?.name}: ${error?.message}`);
    assert.ok(error instanceof Error);
    assert.equal(error.resourceId, '5');
    assert.equal(error.message, 'No user with id=5');
    assert.equal(error.name, 'NotFoundException');
    return true;
  });
});
await check('exception that extends another', async () => {
  await assert.rejects(() => params.throwQuota(), (error) => {
    assert.ok(error instanceof QuotaException, `got ${error?.constructor?.name}: ${error?.message}`);
    assert.ok(error instanceof AppException, 'catchable as its parent');
    assert.equal(error.limit, 3);
    assert.equal(error.message, 'Over quota');
    return true;
  });
});

// ---- annotations and auth ------------------------------------------------
await check('deprecated method still callable', async () => {
  assert.equal(await client.legacy.greet('a'), 'Hi, a');
  assert.equal(await client.legacy.sayHi('b'), 'Hi, b');
});
await check('unauthenticated call', async () => assert.equal(await client.public.ping(), 'pong'));
await check('unauthenticated call sends no credentials', async () =>
  assert.equal(await rejected.public.ping(), 'pong'));
await check('login required, no credentials', async () => {
  await assert.rejects(() => client.auth.secret(), (error) => {
    assert.ok(error instanceof ServerpodClientException);
    assert.equal(error.statusCode, 401);
    return true;
  });
});
await check('login required, wrong credentials', async () => {
  await assert.rejects(() => rejected.auth.secret(), (error) => error.statusCode === 401);
});
await check('login required, valid credentials', async () => {
  assert.equal(await authed.auth.secret(), 'shhh');
  assert.equal(await authed.auth.whoAmI(), 'user-1');
});
await check('a 401 is retried once after the provider refreshes', async () => {
  let token = 'wrong-token';
  let refreshes = 0;
  const refreshing = new Client(host, {
    authKeyProvider: {
      getAuthHeaderValue: async () => `Bearer ${token}`,
      refresh: async () => {
        refreshes++;
        token = 'valid-token';
      },
    },
  });
  assert.equal(await refreshing.auth.whoAmI(), 'user-1');
  assert.equal(refreshes, 1);
});

// ---- streams -------------------------------------------------------------
const s = client.streaming;
await check('output stream', async () => assert.deepEqual(await collect(s.countTo(5)), [1, 2, 3, 4, 5]));
await check('empty output stream', async () => assert.deepEqual(await collect(s.countTo(0)), []));
await check('two streams at once on one connection', async () => {
  const [a, b] = await Promise.all([collect(s.countTo(4)), collect(s.countTo(3))]);
  assert.deepEqual(a, [1, 2, 3, 4]);
  assert.deepEqual(b, [1, 2, 3]);
});
await check('breaking out of an endless stream', async () => {
  const seen = [];
  for await (const value of s.endless()) {
    seen.push(value);
    if (seen.length === 3) break;
  }
  assert.deepEqual(seen, [0, 1, 2]);
});
await check('stream of models', async () => {
  const got = await collect(s.profiles(profile(), 3));
  assert.deepEqual(got.map((x) => x.id), [9, 10, 11]);
  assert.ok(got.every((x) => x instanceof UserProfile));
  assert.equal(got[0].karma, 99999999999999999999n);
});
await check('stream of a sealed type', async () => {
  const [dog, cat] = await collect(s.animals());
  assert.ok(dog instanceof Dog);
  assert.ok(cat instanceof Cat);
  assert.equal(cat.livesRemaining, 9);
});
await check('stream of enums', async () =>
  assert.deepEqual(await collect(s.priorities()), [Priority.Low, Priority.High]));
await check('stream of lists', async () =>
  assert.deepEqual(await collect(s.chunks(3)), [[0], [0, 1], [0, 1, 2]]));
await check('stream that fails with a typed exception', async () => {
  const seen = [];
  await assert.rejects(
    async () => {
      for await (const value of s.failAfter(2)) seen.push(value);
    },
    (error) => {
      assert.ok(error instanceof NotFoundException, `got ${error?.constructor?.name}: ${error?.message}`);
      assert.equal(error.resourceId, '2');
      return true;
    },
  );
  assert.deepEqual(seen, [1, 2]);
});
await check('input stream with a single result', async () => assert.equal(await s.sum({ values: from([1, 2, 3, 4]) }), 10));
await check('empty input stream', async () => assert.equal(await s.sum({ values: from([]) }), 0));
await check('input stream with no result', async () =>
  assert.equal(await s.drain({ values: from(['a', 'b']) }), undefined));
await check('bidirectional stream of strings', async () =>
  assert.deepEqual(await collect(client.chat.echoStream({ messages: from(['a', 'bc']) })), ['A', 'BC']));
await check('bidirectional stream of sealed models', async () => {
  const [dog, cat] = await collect(s.echoAnimals({ animals: from([rex(), tom()]) }));
  assert.ok(dog instanceof Dog);
  assert.equal(dog.breed, 'Collie');
  assert.ok(cat instanceof Cat);
  assert.equal(cat.name, 'Tom');
});
await check('lists as input stream values', async () =>
  assert.deepEqual(await collect(s.describeLists({ lists: from([[1, 2], []]) })), ['list:1,2', 'list:']));
await check('enums as input stream values', async () =>
  assert.deepEqual(
    await collect(s.describePriorities({ priorities: from([Priority.High, Priority.Low]) })),
    ['priority:high', 'priority:low'],
  ));
await check('stream needing login, no credentials', async () => {
  await assert.rejects(() => collect(client.auth.whoAmIStream()), (error) => {
    assert.equal(error.statusCode, 401, `status ${error.statusCode}: ${error.message}`);
    return true;
  });
});
await check('stream needing login, valid credentials', async () =>
  assert.deepEqual(await collect(authed.auth.whoAmIStream()), ['user-1']));
await check('unknown endpoint over HTTP', async () => {
  await assert.rejects(
    () => client.callServerEndpoint('nope', 'nothing', {}, (raw) => raw),
    (error) => error instanceof ServerpodClientException && error.statusCode >= 400,
  );
});

// ---- report --------------------------------------------------------------
for (const { name, error } of results) {
  console.log(error ? `FAIL  ${name}` : `ok    ${name}`);
  if (error) {
    const detail = String(error.stack ?? error.message ?? error).split('\n').slice(0, 4);
    for (const line of detail) console.log(`        ${line}`);
  }
}
const failed = results.filter((r) => r.error).length;
console.log(`${results.length - failed}/${results.length} passed`);
process.exit(failed ? 1 : 0);
