const { readFile, writeFile } = require('fs').promises;

const getMeetups = async () =>
  JSON.parse(
    await readFile(`${__dirname}/../src/files/data/meetups.json`, {
      encoding: 'utf8'
    })
  ).sort((a, b) => a.on > b.on);

const uniqueSpeakers = meetups => {
  return Object.values(
    meetups.reduce((result, meetup) => {
      const { speakers, on } = meetup;

      speakers.forEach(({ email, name }) => {
        if (!result[name]) {
          result[name] = {
            email: [],
            name,
            on: [],
            count: 0
          };
        }

        const current = result[name];
        if (!current.email.includes(email)) current.email.push(email);
        current.on.push(on);
        current.count += 1;
      });

      return result;
    }, {})
  );
};

(async () => {
  const meetups = await getMeetups();
  const uniques = uniqueSpeakers(meetups);

  const stats = meetups.reduce(
    (memo, meetup) => {
      memo.talks += meetup.speakers.length;
      memo.num += 1;
      return memo;
    },
    { talks: 0, num: 0 }
  );

  stats.top10 = uniques
    .sort((a, b) => b.count - a.count)
    .slice(0, 12)
    .map(({ name, email, count, on }) => ({
      name,
      email,
      count,
      on
    }));

  await writeFile('ten-years.json', JSON.stringify(uniques));
  await writeFile('ten-years-stats.json', JSON.stringify(stats));

  // csv output
  const header = '"Speaker Name","Email","Dates"\n';
  const csv =
    header +
    uniques.reduce((str, { name, email, on }) => {
      str += `"${name}","${email.join('\n')}","${on.join('\n')}"\n`;
      return str;
    }, '');
  await writeFile('ten-years.csv', csv);
})();
