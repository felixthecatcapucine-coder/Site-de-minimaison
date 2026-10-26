// Vercel ne sait pas ouvrir un zip : ce petit script, lancé par Vercel avant
// la mise en ligne (voir « buildCommand » dans vercel.json), décompresse
// MiniMaisons-vercel.zip dans le dossier « public », qui devient le site.
// Il n'utilise que Node.js : rien à installer.
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const zip = fs.readFileSync(path.join(__dirname, 'MiniMaisons-vercel.zip'));
const sortie = path.join(__dirname, 'public');
fs.rmSync(sortie, { recursive: true, force: true });

// La fin du zip dit combien il contient de fichiers et où commence leur liste.
let fin = zip.length - 22;
while (fin >= 0 && zip.readUInt32LE(fin) !== 0x06054b50) fin--;
if (fin < 0) throw new Error("MiniMaisons-vercel.zip n'est pas un zip valide.");
const nombre = zip.readUInt16LE(fin + 10);
let position = zip.readUInt32LE(fin + 16);

let fichiers = 0;
for (let i = 0; i < nombre; i++) {
  // Une ligne de la liste : méthode, taille, nom, et où sont les données.
  if (zip.readUInt32LE(position) !== 0x02014b50) throw new Error('Zip abîmé.');
  const methode = zip.readUInt16LE(position + 10);
  const taille = zip.readUInt32LE(position + 20);
  const longueurNom = zip.readUInt16LE(position + 28);
  const longueurSuite =
    zip.readUInt16LE(position + 30) + zip.readUInt16LE(position + 32);
  const entete = zip.readUInt32LE(position + 42);
  const nom = zip.toString('utf8', position + 46, position + 46 + longueurNom);
  position += 46 + longueurNom + longueurSuite;

  // Les dossiers se créent avec leurs fichiers.
  if (nom.endsWith('/')) continue;

  // Les données suivent l'en-tête du fichier, qui a sa propre longueur.
  const debut = entete + 30 + zip.readUInt16LE(entete + 26) + zip.readUInt16LE(entete + 28);
  const donnees = zip.subarray(debut, debut + taille);
  let contenu;
  if (methode === 0) contenu = donnees; // rangé sans compression
  else if (methode === 8) contenu = zlib.inflateRawSync(donnees); // compressé
  else throw new Error(`Compression inconnue pour ${nom}.`);

  // Par sécurité, rien ne doit sortir du dossier « public ».
  const cible = path.join(sortie, nom);
  if (!cible.startsWith(sortie + path.sep)) throw new Error(`Chemin refusé : ${nom}`);
  fs.mkdirSync(path.dirname(cible), { recursive: true });
  fs.writeFileSync(cible, contenu);
  fichiers++;
}

if (!fs.existsSync(path.join(sortie, 'index.html'))) {
  throw new Error("Le zip ne contient pas index.html à sa racine.");
}
console.log(`Site prêt : ${fichiers} fichiers dans public/`);
