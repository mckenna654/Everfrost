// Build the installable addon using Node's standard library on any platform.
const fs = require('node:fs');
const path = require('node:path');
const zlib = require('node:zlib');
const root = path.resolve(__dirname, '..');
const source = path.join(root, 'addon', 'Everfrost');
const version = require(path.join(root, 'package.json')).version;
if (!/^\d+\.\d+\.\d+$/.test(version)) throw new Error('Invalid addon version');
for (const file of [path.join(source, 'Everfrost.toc'), path.join(root, 'Everfrost-Source.toc')]) {
  if (!fs.readFileSync(file, 'utf8').includes('## Version: ' + version)) throw new Error('TOC version mismatch');
}
const crcTable = Array.from({length:256}, (_, value) => {
  for (let i=0; i<8; i++) value = (value & 1) ? 0xedb88320 ^ (value >>> 1) : value >>> 1;
  return value >>> 0;
});
function crc32(data) {
  let crc = 0xffffffff;
  for (const byte of data) crc = crcTable[(crc ^ byte) & 255] ^ (crc >>> 8);
  return (crc ^ 0xffffffff) >>> 0;
}
const chunks=[], central=[];
let offset=0, count=0;
function add(directory, relative='') {
  for (const entry of fs.readdirSync(directory, {withFileTypes:true}).sort((a,b)=>a.name.localeCompare(b.name))) {
    if (entry.name.startsWith('.')) continue;
    const file = path.join(directory, entry.name);
    const name = relative + entry.name;
    if (entry.isDirectory()) { add(file, name + '/'); continue; }
    if (!entry.isFile()) throw new Error('Unsupported addon entry: ' + name);
    const filename=Buffer.from('Everfrost/' + name);
    const data=fs.readFileSync(file), compressed=zlib.deflateRawSync(data), crc=crc32(data);
    const header=Buffer.alloc(30);
    header.writeUInt32LE(0x04034b50,0); header.writeUInt16LE(20,4);
    header.writeUInt16LE(0x800,6); header.writeUInt16LE(8,8);
    header.writeUInt16LE(33,12); // DOS epoch, deterministic ZIP timestamps.
    header.writeUInt32LE(crc,14); header.writeUInt32LE(compressed.length,18);
    header.writeUInt32LE(data.length,22); header.writeUInt16LE(filename.length,26);
    const directoryHeader=Buffer.alloc(46);
    directoryHeader.writeUInt32LE(0x02014b50,0); directoryHeader.writeUInt16LE(20,4);
    directoryHeader.writeUInt16LE(20,6); directoryHeader.writeUInt16LE(0x800,8);
    directoryHeader.writeUInt16LE(8,10); directoryHeader.writeUInt16LE(33,14);
    directoryHeader.writeUInt32LE(crc,16); directoryHeader.writeUInt32LE(compressed.length,20);
    directoryHeader.writeUInt32LE(data.length,24); directoryHeader.writeUInt16LE(filename.length,28);
    directoryHeader.writeUInt32LE(offset,42);
    chunks.push(header,filename,compressed); central.push(directoryHeader,filename);
    offset+=header.length+filename.length+compressed.length; count++;
  }
}
add(source);
const directory=Buffer.concat(central), end=Buffer.alloc(22);
end.writeUInt32LE(0x06054b50,0); end.writeUInt16LE(count,8); end.writeUInt16LE(count,10);
end.writeUInt32LE(directory.length,12); end.writeUInt32LE(offset,16);
fs.mkdirSync(path.join(root,'dist'),{recursive:true});
const output=path.join(root,'dist',`Everfrost-${version}.zip`);
fs.writeFileSync(output,Buffer.concat([...chunks,directory,end]));
console.log(output);
