/// 星座定義データ.
///
/// 黄道十二星座 + メジャー星座 + マイナー星座を含む全36星座.
/// 座標は0.0〜1.0の正規化座標で、描画時にウィジェットサイズにスケーリングする.
library;

import '../models/constellation.dart';

/// 1つの星を点灯するのに必要な活動時間（分）.
const minutesPerStar = 300; // 5時間

/// 利用可能な星座一覧.
const constellations = <ConstellationDef>[
  // ========================================
  // 黄道十二星座
  // ========================================

  // おひつじ座 (Aries)
  ConstellationDef(
    id: 'aries',
    name: 'Aries',
    jaName: 'おひつじ座',
    symbol: '\u2648',
    description: '黄道十二星座の1番目。最も明るい星はハマル（α星、2.0等級）で、'
        'アラビア語で「羊の頭」を意味する。ギリシャ神話では、金の毛皮を持つ空飛ぶ牡羊を表す。'
        '春分点がかつてこの星座にあったため、「白羊宮」と呼ばれた。',
    stars: [
      StarPosition(0.20, 0.40),
      StarPosition(0.30, 0.35),
      StarPosition(0.45, 0.30),
      StarPosition(0.55, 0.35),
      StarPosition(0.65, 0.45),
      StarPosition(0.75, 0.40),
      StarPosition(0.60, 0.55),
      StarPosition(0.50, 0.60),
    ],
    connections: [
      StarConnection(0, 1),
      StarConnection(1, 2),
      StarConnection(2, 3),
      StarConnection(3, 4),
      StarConnection(4, 5),
      StarConnection(3, 6),
      StarConnection(6, 7),
    ],
  ),

  // おうし座 (Taurus)
  ConstellationDef(
    id: 'taurus',
    name: 'Taurus',
    jaName: 'おうし座',
    symbol: '\u2649',
    description: '最も明るい星アルデバラン（α星、0.85等級）はオレンジ色の巨星で、'
        'アラビア語で「追う者」を意味する。プレアデス星団（すばる）とヒアデス星団という'
        '2つの有名な散開星団を含む。プレアデス星団は肉眼で6〜7個の星が見える。',
    stars: [
      StarPosition(0.15, 0.55),
      StarPosition(0.25, 0.45),
      StarPosition(0.35, 0.40),
      StarPosition(0.50, 0.35),
      StarPosition(0.60, 0.25),
      StarPosition(0.70, 0.30),
      StarPosition(0.55, 0.45),
      StarPosition(0.45, 0.55),
      StarPosition(0.65, 0.50),
      StarPosition(0.75, 0.45),
    ],
    connections: [
      StarConnection(0, 1),
      StarConnection(1, 2),
      StarConnection(2, 3),
      StarConnection(3, 4),
      StarConnection(4, 5),
      StarConnection(3, 6),
      StarConnection(6, 7),
      StarConnection(6, 8),
      StarConnection(8, 9),
    ],
  ),

  // ふたご座 (Gemini)
  ConstellationDef(
    id: 'gemini',
    name: 'Gemini',
    jaName: 'ふたご座',
    symbol: '\u264A',
    description: '双子の兄弟カストルとポルックスを表す。ポルックス（β星、1.14等級）は'
        'おうし座に次ぐ明るさを持つオレンジ色の巨星。カストル（α星）は実際には6つの星からなる'
        '六重連星系。毎年12月中旬にはふたご座流星群が極大を迎える。',
    stars: [
      StarPosition(0.30, 0.20),
      StarPosition(0.35, 0.35),
      StarPosition(0.30, 0.50),
      StarPosition(0.25, 0.65),
      StarPosition(0.60, 0.20),
      StarPosition(0.55, 0.35),
      StarPosition(0.60, 0.50),
      StarPosition(0.65, 0.65),
      StarPosition(0.45, 0.30),
    ],
    connections: [
      StarConnection(0, 1),
      StarConnection(1, 2),
      StarConnection(2, 3),
      StarConnection(4, 5),
      StarConnection(5, 6),
      StarConnection(6, 7),
      StarConnection(1, 8),
      StarConnection(8, 5),
    ],
  ),

  // かに座 (Cancer)
  ConstellationDef(
    id: 'cancer',
    name: 'Cancer',
    jaName: 'かに座',
    symbol: '\u264B',
    description: '黄道十二星座の中で最も暗い星座。最も明るい星でも3.5等級だが、'
        '中心付近にあるプレセペ星団（M44）は肉眼でもぼんやり見える散開星団で、'
        '約1,000個の星からなる。ラテン名「Cancer」は蟹を意味し、'
        'ヘラクレスと戦った化け蟹が由来。',
    stars: [
      StarPosition(0.30, 0.35),
      StarPosition(0.40, 0.45),
      StarPosition(0.55, 0.45),
      StarPosition(0.65, 0.35),
      StarPosition(0.35, 0.55),
      StarPosition(0.60, 0.55),
      StarPosition(0.45, 0.30),
      StarPosition(0.50, 0.60),
    ],
    connections: [
      StarConnection(0, 1),
      StarConnection(1, 2),
      StarConnection(2, 3),
      StarConnection(1, 4),
      StarConnection(2, 5),
      StarConnection(1, 6),
      StarConnection(2, 7),
    ],
  ),

  // しし座 (Leo)
  ConstellationDef(
    id: 'leo',
    name: 'Leo',
    jaName: 'しし座',
    symbol: '\u264C',
    description: '春の夜空を代表する星座。最も明るいレグルス（α星、1.4等級）は'
        '「小さな王」を意味し、黄道上にある1等星。頭部の星の並びは「獅子の大鎌」と呼ばれる'
        '逆疑問符の形をしている。ヘラクレスが退治したネメアの獅子が由来。',
    stars: [
      StarPosition(0.20, 0.35),
      StarPosition(0.30, 0.25),
      StarPosition(0.40, 0.20),
      StarPosition(0.50, 0.30),
      StarPosition(0.45, 0.45),
      StarPosition(0.55, 0.50),
      StarPosition(0.65, 0.45),
      StarPosition(0.70, 0.55),
      StarPosition(0.75, 0.65),
      StarPosition(0.60, 0.60),
    ],
    connections: [
      StarConnection(0, 1),
      StarConnection(1, 2),
      StarConnection(2, 3),
      StarConnection(3, 4),
      StarConnection(4, 5),
      StarConnection(5, 6),
      StarConnection(6, 7),
      StarConnection(7, 8),
      StarConnection(8, 9),
      StarConnection(9, 5),
    ],
  ),

  // おとめ座 (Virgo)
  ConstellationDef(
    id: 'virgo',
    name: 'Virgo',
    jaName: 'おとめ座',
    symbol: '\u264D',
    description: '全天で2番目に大きい星座。最も明るいスピカ（α星、0.97等級）は'
        '青白い1等星で「麦の穂」を意味する。おとめ座銀河団は約2,000個の銀河からなり、'
        '地球から約5,400万光年に位置する。秋分点がこの星座にある。',
    stars: [
      StarPosition(0.25, 0.30),
      StarPosition(0.35, 0.35),
      StarPosition(0.45, 0.40),
      StarPosition(0.55, 0.35),
      StarPosition(0.65, 0.30),
      StarPosition(0.50, 0.50),
      StarPosition(0.40, 0.60),
      StarPosition(0.55, 0.65),
      StarPosition(0.70, 0.50),
    ],
    connections: [
      StarConnection(0, 1),
      StarConnection(1, 2),
      StarConnection(2, 3),
      StarConnection(3, 4),
      StarConnection(2, 5),
      StarConnection(5, 6),
      StarConnection(5, 7),
      StarConnection(3, 8),
    ],
  ),

  // てんびん座 (Libra)
  ConstellationDef(
    id: 'libra',
    name: 'Libra',
    jaName: 'てんびん座',
    symbol: '\u264E',
    description: '黄道十二星座で唯一、生物ではなく道具を表す星座。'
        'かつてはさそり座の一部（はさみ）とされていた。α星のズベンエルゲヌビは'
        'アラビア語で「南の爪」、β星のズベンエスカマリは「北の爪」を意味し、'
        'さそり座との歴史的関係を示している。',
    stars: [
      StarPosition(0.30, 0.30),
      StarPosition(0.50, 0.25),
      StarPosition(0.70, 0.30),
      StarPosition(0.40, 0.50),
      StarPosition(0.50, 0.45),
      StarPosition(0.60, 0.50),
      StarPosition(0.50, 0.65),
    ],
    connections: [
      StarConnection(0, 1),
      StarConnection(1, 2),
      StarConnection(0, 3),
      StarConnection(3, 4),
      StarConnection(4, 5),
      StarConnection(5, 2),
      StarConnection(4, 6),
    ],
  ),

  // さそり座 (Scorpius)
  ConstellationDef(
    id: 'scorpius',
    name: 'Scorpius',
    jaName: 'さそり座',
    symbol: '\u264F',
    description: '夏の南の空に横たわる大きな星座。心臓にあたるアンタレス（α星、1.1等級）は'
        '「火星に対抗するもの」を意味する赤色超巨星で、直径は太陽の約700倍。'
        'S字形のカーブが特徴的で、ギリシャ神話ではオリオンを刺した蠍とされる。',
    stars: [
      StarPosition(0.15, 0.30),
      StarPosition(0.25, 0.35),
      StarPosition(0.35, 0.40),
      StarPosition(0.45, 0.45),
      StarPosition(0.55, 0.50),
      StarPosition(0.60, 0.55),
      StarPosition(0.65, 0.60),
      StarPosition(0.70, 0.55),
      StarPosition(0.75, 0.45),
      StarPosition(0.80, 0.40),
    ],
    connections: [
      StarConnection(0, 1),
      StarConnection(1, 2),
      StarConnection(2, 3),
      StarConnection(3, 4),
      StarConnection(4, 5),
      StarConnection(5, 6),
      StarConnection(6, 7),
      StarConnection(7, 8),
      StarConnection(8, 9),
    ],
  ),

  // いて座 (Sagittarius)
  ConstellationDef(
    id: 'sagittarius',
    name: 'Sagittarius',
    jaName: 'いて座',
    symbol: '\u2650',
    description: '天の川の最も濃い部分に位置し、銀河系の中心方向にある。'
        '「南斗六星」と呼ばれるひしゃく形のアステリズムが有名。'
        '干潟星雲（M8）、三裂星雲（M20）、オメガ星雲（M17）など多くの星雲・星団が'
        'この方向に集中している。',
    stars: [
      StarPosition(0.30, 0.25),
      StarPosition(0.40, 0.35),
      StarPosition(0.50, 0.30),
      StarPosition(0.55, 0.40),
      StarPosition(0.45, 0.50),
      StarPosition(0.60, 0.55),
      StarPosition(0.50, 0.65),
      StarPosition(0.65, 0.45),
      StarPosition(0.70, 0.35),
    ],
    connections: [
      StarConnection(0, 1),
      StarConnection(1, 2),
      StarConnection(2, 3),
      StarConnection(3, 4),
      StarConnection(4, 5),
      StarConnection(5, 6),
      StarConnection(3, 7),
      StarConnection(7, 8),
    ],
  ),

  // やぎ座 (Capricornus)
  ConstellationDef(
    id: 'capricornus',
    name: 'Capricornus',
    jaName: 'やぎ座',
    symbol: '\u2651',
    description: '上半身が山羊、下半身が魚という不思議な姿の星座。'
        'バビロニア時代から知られる最も古い星座の一つ。'
        'かつて冬至点がこの星座にあったため、南回帰線は英語で'
        '「Tropic of Capricorn」と呼ばれる。α星は肉眼で二重星として見える。',
    stars: [
      StarPosition(0.25, 0.35),
      StarPosition(0.35, 0.30),
      StarPosition(0.50, 0.25),
      StarPosition(0.65, 0.30),
      StarPosition(0.70, 0.40),
      StarPosition(0.60, 0.55),
      StarPosition(0.45, 0.60),
      StarPosition(0.30, 0.50),
    ],
    connections: [
      StarConnection(0, 1),
      StarConnection(1, 2),
      StarConnection(2, 3),
      StarConnection(3, 4),
      StarConnection(4, 5),
      StarConnection(5, 6),
      StarConnection(6, 7),
      StarConnection(7, 0),
    ],
  ),

  // みずがめ座 (Aquarius)
  ConstellationDef(
    id: 'aquarius',
    name: 'Aquarius',
    jaName: 'みずがめ座',
    symbol: '\u2652',
    description: '水瓶から水を注ぐ人の姿を表す。らせん星雲（NGC 7293）は'
        '地球に最も近い惑星状星雲の一つで、約700光年先にある。'
        '土星状星雲（NGC 7009）も有名な惑星状星雲。'
        '5月上旬にはみずがめ座η流星群が見られる。',
    stars: [
      StarPosition(0.20, 0.30),
      StarPosition(0.30, 0.25),
      StarPosition(0.40, 0.30),
      StarPosition(0.50, 0.25),
      StarPosition(0.55, 0.35),
      StarPosition(0.50, 0.50),
      StarPosition(0.60, 0.55),
      StarPosition(0.70, 0.60),
      StarPosition(0.65, 0.45),
    ],
    connections: [
      StarConnection(0, 1),
      StarConnection(1, 2),
      StarConnection(2, 3),
      StarConnection(3, 4),
      StarConnection(4, 5),
      StarConnection(5, 6),
      StarConnection(6, 7),
      StarConnection(4, 8),
    ],
  ),

  // うお座 (Pisces)
  ConstellationDef(
    id: 'pisces',
    name: 'Pisces',
    jaName: 'うお座',
    symbol: '\u2653',
    description: '2匹の魚がリボンで結ばれた姿を表す大きな星座。'
        '現在の春分点はこの星座にある（歳差運動により約2,000年前におひつじ座から移動）。'
        '渦巻銀河M74は望遠鏡で観測できるフェイスオン銀河として知られる。'
        '全体的に暗い星が多く、都市部では見つけにくい。',
    stars: [
      StarPosition(0.20, 0.40),
      StarPosition(0.25, 0.30),
      StarPosition(0.35, 0.25),
      StarPosition(0.45, 0.30),
      StarPosition(0.50, 0.40),
      StarPosition(0.55, 0.50),
      StarPosition(0.65, 0.45),
      StarPosition(0.75, 0.40),
      StarPosition(0.70, 0.55),
      StarPosition(0.60, 0.60),
    ],
    connections: [
      StarConnection(0, 1),
      StarConnection(1, 2),
      StarConnection(2, 3),
      StarConnection(3, 4),
      StarConnection(4, 5),
      StarConnection(5, 6),
      StarConnection(6, 7),
      StarConnection(6, 8),
      StarConnection(8, 9),
      StarConnection(9, 5),
    ],
  ),

  // ========================================
  // メジャー星座
  // ========================================

  // オリオン座 (Orion) - 冬の代表的な星座
  ConstellationDef(
    id: 'orion',
    name: 'Orion',
    jaName: 'オリオン座',
    symbol: '\u2694', // crossed swords
    description: '全天で最も有名な星座の一つ。左上のベテルギウス（0.4等級）は赤色超巨星で'
        '直径は太陽の約1,000倍、右下のリゲル（0.1等級）は青白い超巨星。'
        '三つ星の下にあるオリオン大星雲（M42）は約1,344光年先にある巨大な星形成領域で、'
        '肉眼でもぼんやり見える。',
    stars: [
      StarPosition(0.35, 0.15), // ベテルギウス
      StarPosition(0.65, 0.15), // ベラトリックス
      StarPosition(0.40, 0.40), // 三つ星左
      StarPosition(0.50, 0.42), // 三つ星中
      StarPosition(0.60, 0.40), // 三つ星右
      StarPosition(0.35, 0.70), // サイフ
      StarPosition(0.65, 0.70), // リゲル
      StarPosition(0.50, 0.55), // 小三つ星中
      StarPosition(0.30, 0.45), // 左腕
      StarPosition(0.70, 0.30), // 右腕
    ],
    connections: [
      StarConnection(0, 1),
      StarConnection(0, 2),
      StarConnection(1, 4),
      StarConnection(2, 3),
      StarConnection(3, 4),
      StarConnection(2, 5),
      StarConnection(4, 6),
      StarConnection(3, 7),
      StarConnection(0, 8),
      StarConnection(1, 9),
    ],
  ),

  // おおぐま座 (Ursa Major) - 北斗七星を含む
  ConstellationDef(
    id: 'ursa_major',
    name: 'Ursa Major',
    jaName: 'おおぐま座',
    symbol: '\u{1F43B}', // bear
    description: '全天で3番目に大きい星座で、北斗七星を含む。'
        '北斗七星の柄の端から2番目のミザール（2.2等級）には肉眼二重星のアルコルが寄り添い、'
        '古くから視力検査に使われた。北斗七星の先端の2星を延長すると北極星に至る。'
        '回転花火銀河（M101）やボーデの銀河（M81）など多くの銀河が存在する。',
    stars: [
      StarPosition(0.20, 0.40), // 柄の先端
      StarPosition(0.30, 0.35), // 柄2
      StarPosition(0.40, 0.38), // 柄3
      StarPosition(0.50, 0.35), // 器の角1
      StarPosition(0.65, 0.32), // 器の角2
      StarPosition(0.65, 0.50), // 器の角3
      StarPosition(0.50, 0.50), // 器の角4
    ],
    connections: [
      StarConnection(0, 1),
      StarConnection(1, 2),
      StarConnection(2, 3),
      StarConnection(3, 4),
      StarConnection(4, 5),
      StarConnection(5, 6),
      StarConnection(6, 3),
    ],
  ),

  // カシオペヤ座 (Cassiopeia) - W字型
  ConstellationDef(
    id: 'cassiopeia',
    name: 'Cassiopeia',
    jaName: 'カシオペヤ座',
    symbol: '\u{1F451}', // crown
    description: '北極星の反対側でW字型（またはM字型）に並ぶ5つの星が特徴的な周極星座。'
        'ギリシャ神話のエチオピア王妃カシオペアが由来。'
        '1572年にティコ・ブラーエがこの星座内で超新星（ティコの新星）を観測し、'
        '天体が不変であるという当時の常識を覆した。',
    stars: [
      StarPosition(0.15, 0.45),
      StarPosition(0.30, 0.30),
      StarPosition(0.45, 0.50),
      StarPosition(0.60, 0.25),
      StarPosition(0.75, 0.40),
    ],
    connections: [
      StarConnection(0, 1),
      StarConnection(1, 2),
      StarConnection(2, 3),
      StarConnection(3, 4),
    ],
  ),

  // はくちょう座 (Cygnus) - 北十字
  ConstellationDef(
    id: 'cygnus',
    name: 'Cygnus',
    jaName: 'はくちょう座',
    symbol: '\u{1F9A2}', // swan
    description: '夏の大三角の一角デネブ（α星、1.25等級）を持つ。デネブは太陽の約20万倍の'
        '明るさを持つ白色超巨星で、地球から約2,600光年と1等星の中で最も遠い星の一つ。'
        '十字形の星の並びは「北十字」とも呼ばれる。'
        'くちばしにあたるアルビレオは美しい二重星として有名。',
    stars: [
      StarPosition(0.50, 0.15), // デネブ（尾）
      StarPosition(0.50, 0.35),
      StarPosition(0.50, 0.55),
      StarPosition(0.50, 0.75), // アルビレオ（くちばし）
      StarPosition(0.30, 0.40), // 左翼
      StarPosition(0.70, 0.40), // 右翼
      StarPosition(0.20, 0.50), // 左翼先
      StarPosition(0.80, 0.50), // 右翼先
    ],
    connections: [
      StarConnection(0, 1),
      StarConnection(1, 2),
      StarConnection(2, 3),
      StarConnection(1, 4),
      StarConnection(1, 5),
      StarConnection(4, 6),
      StarConnection(5, 7),
    ],
  ),

  // わし座 (Aquila) - アルタイルを含む
  ConstellationDef(
    id: 'aquila',
    name: 'Aquila',
    jaName: 'わし座',
    symbol: '\u{1F985}', // eagle
    description: '夏の大三角の一角アルタイル（α星、0.77等級）を持つ。'
        'アルタイルは地球から約17光年と比較的近く、'
        '高速自転（約9時間で1回転）のため赤道方向に膨らんだ楕円体の形をしている。'
        '七夕伝説では織姫（ベガ）と天の川を挟んで向かい合う彦星として知られる。',
    stars: [
      StarPosition(0.50, 0.25), // アルタイル
      StarPosition(0.35, 0.35),
      StarPosition(0.65, 0.35),
      StarPosition(0.45, 0.50),
      StarPosition(0.55, 0.50),
      StarPosition(0.40, 0.65),
      StarPosition(0.60, 0.65),
    ],
    connections: [
      StarConnection(0, 1),
      StarConnection(0, 2),
      StarConnection(1, 3),
      StarConnection(2, 4),
      StarConnection(3, 5),
      StarConnection(4, 6),
    ],
  ),

  // こと座 (Lyra) - ベガを含む
  ConstellationDef(
    id: 'lyra',
    name: 'Lyra',
    jaName: 'こと座',
    symbol: '\u{1F3B5}', // music note
    description: '夏の大三角で最も明るいベガ（α星、0.03等級）を持つ。'
        'ベガは全天で5番目に明るい恒星で、約12,000年後には歳差運動により北極星となる。'
        '環状星雲（M57）はドーナツ型の惑星状星雲として天体望遠鏡で人気の天体。'
        '七夕伝説では織姫星として知られる。',
    stars: [
      StarPosition(0.50, 0.20), // ベガ
      StarPosition(0.40, 0.40),
      StarPosition(0.60, 0.40),
      StarPosition(0.35, 0.60),
      StarPosition(0.65, 0.60),
      StarPosition(0.50, 0.70),
    ],
    connections: [
      StarConnection(0, 1),
      StarConnection(0, 2),
      StarConnection(1, 3),
      StarConnection(2, 4),
      StarConnection(3, 5),
      StarConnection(4, 5),
    ],
  ),

  // おおいぬ座 (Canis Major) - シリウスを含む
  ConstellationDef(
    id: 'canis_major',
    name: 'Canis Major',
    jaName: 'おおいぬ座',
    symbol: '\u{1F415}', // dog
    description: '全天で最も明るい恒星シリウス（α星、-1.46等級）を持つ。'
        'シリウスは地球から約8.6光年と近く、太陽の約25倍の明るさ。'
        '古代エジプトではシリウスの日の出前の出現がナイル川の増水と農耕の始まりを告げた。'
        '実は白色矮星の伴星（シリウスB）を持つ連星系である。',
    stars: [
      StarPosition(0.45, 0.15), // シリウス
      StarPosition(0.35, 0.30),
      StarPosition(0.55, 0.30),
      StarPosition(0.30, 0.45),
      StarPosition(0.60, 0.45),
      StarPosition(0.25, 0.60),
      StarPosition(0.50, 0.60),
      StarPosition(0.65, 0.55),
    ],
    connections: [
      StarConnection(0, 1),
      StarConnection(0, 2),
      StarConnection(1, 3),
      StarConnection(2, 4),
      StarConnection(3, 5),
      StarConnection(3, 6),
      StarConnection(4, 7),
    ],
  ),

  // ペルセウス座 (Perseus) - 英雄の星座
  ConstellationDef(
    id: 'perseus',
    name: 'Perseus',
    jaName: 'ペルセウス座',
    symbol: '\u{1F5E1}', // dagger
    description: 'メドゥーサを退治した英雄ペルセウスを表す。β星アルゴル（2.1等級）は'
        '最も有名な食変光星で、約2日21時間の周期で明るさが変化する。'
        'アラビア語で「悪魔の頭」を意味し、ペルセウスが持つメドゥーサの首にあたる。'
        '8月中旬のペルセウス座流星群は三大流星群の一つ。',
    stars: [
      StarPosition(0.50, 0.15),
      StarPosition(0.45, 0.30),
      StarPosition(0.40, 0.45),
      StarPosition(0.35, 0.55),
      StarPosition(0.30, 0.70),
      StarPosition(0.55, 0.45),
      StarPosition(0.65, 0.55),
      StarPosition(0.60, 0.35),
      StarPosition(0.25, 0.40),
    ],
    connections: [
      StarConnection(0, 1),
      StarConnection(1, 2),
      StarConnection(2, 3),
      StarConnection(3, 4),
      StarConnection(2, 5),
      StarConnection(5, 6),
      StarConnection(1, 7),
      StarConnection(2, 8),
    ],
  ),

  // アンドロメダ座 (Andromeda)
  ConstellationDef(
    id: 'andromeda',
    name: 'Andromeda',
    jaName: 'アンドロメダ座',
    symbol: '\u{1F30C}', // milky way
    description: '肉眼で見える最も遠い天体、アンドロメダ銀河（M31）を含む。'
        'M31は約254万光年先にある渦巻銀河で、天の川銀河の約2倍の大きさを持ち、'
        '約45億年後に天の川銀河と衝突・合体すると予測されている。'
        'ギリシャ神話では海の怪物の生贄にされた王女アンドロメダが由来。',
    stars: [
      StarPosition(0.15, 0.45),
      StarPosition(0.30, 0.40),
      StarPosition(0.45, 0.38),
      StarPosition(0.60, 0.35),
      StarPosition(0.75, 0.30),
      StarPosition(0.35, 0.25),
      StarPosition(0.55, 0.50),
      StarPosition(0.70, 0.55),
    ],
    connections: [
      StarConnection(0, 1),
      StarConnection(1, 2),
      StarConnection(2, 3),
      StarConnection(3, 4),
      StarConnection(1, 5),
      StarConnection(3, 6),
      StarConnection(6, 7),
    ],
  ),

  // ペガスス座 (Pegasus) - 秋の四辺形
  ConstellationDef(
    id: 'pegasus',
    name: 'Pegasus',
    jaName: 'ペガスス座',
    symbol: '\u{1F40E}', // horse
    description: '秋の夜空で目立つ「ペガススの四辺形」が特徴。4つの2等級の星が'
        '大きな正方形を描く（ただし1つはアンドロメダ座α星）。'
        '1995年にこの星座の51番星で初めて太陽型恒星を周回する'
        '系外惑星が発見され、発見者は2019年にノーベル物理学賞を受賞した。',
    stars: [
      StarPosition(0.30, 0.25), // 四辺形の角
      StarPosition(0.65, 0.25),
      StarPosition(0.65, 0.55),
      StarPosition(0.30, 0.55),
      StarPosition(0.15, 0.40), // 首
      StarPosition(0.20, 0.60), // 前脚
      StarPosition(0.80, 0.40), // 後ろ
      StarPosition(0.75, 0.65), // 後脚
    ],
    connections: [
      StarConnection(0, 1),
      StarConnection(1, 2),
      StarConnection(2, 3),
      StarConnection(3, 0),
      StarConnection(3, 4),
      StarConnection(3, 5),
      StarConnection(1, 6),
      StarConnection(2, 7),
    ],
  ),

  // りゅう座 (Draco) - 北極星の近く
  ConstellationDef(
    id: 'draco',
    name: 'Draco',
    jaName: 'りゅう座',
    symbol: '\u{1F409}', // dragon
    description: 'おおぐま座とこぐま座の間を蛇行する大きな周極星座。'
        '約4,700年前にはα星トゥバン（3.7等級）が北極星だった。'
        'エジプトのピラミッド建設時代にはトゥバンが真北を示していたとされる。'
        'キャッツアイ星雲（NGC 6543）は複雑な構造を持つ惑星状星雲として有名。',
    stars: [
      StarPosition(0.25, 0.25), // 頭
      StarPosition(0.35, 0.20),
      StarPosition(0.30, 0.35),
      StarPosition(0.40, 0.40),
      StarPosition(0.55, 0.35),
      StarPosition(0.65, 0.40),
      StarPosition(0.70, 0.50),
      StarPosition(0.60, 0.60),
      StarPosition(0.50, 0.55),
      StarPosition(0.45, 0.65),
    ],
    connections: [
      StarConnection(0, 1),
      StarConnection(0, 2),
      StarConnection(2, 3),
      StarConnection(3, 4),
      StarConnection(4, 5),
      StarConnection(5, 6),
      StarConnection(6, 7),
      StarConnection(7, 8),
      StarConnection(8, 9),
    ],
  ),

  // みなみじゅうじ座 (Crux) - 南十字星
  ConstellationDef(
    id: 'crux',
    name: 'Crux',
    jaName: 'みなみじゅうじ座',
    symbol: '\u271A', // cross
    description: '全88星座の中で最も小さい星座だが、南半球では最も有名。'
        'オーストラリア、ニュージーランド、ブラジルなどの国旗に描かれている。'
        '十字の長い方の軸を約4.5倍延長すると天の南極の位置がわかる。'
        'α星アクルックス（0.8等級）は実際には二重星。',
    stars: [
      StarPosition(0.50, 0.15), // 上
      StarPosition(0.50, 0.70), // 下
      StarPosition(0.25, 0.42), // 左
      StarPosition(0.75, 0.42), // 右
      StarPosition(0.55, 0.50), // 中心近く
    ],
    connections: [
      StarConnection(0, 1),
      StarConnection(2, 3),
      StarConnection(0, 4),
      StarConnection(4, 1),
    ],
  ),

  // ========================================
  // マイナー星座
  // ========================================

  // からす座 (Corvus) - 春の小さな四辺形
  ConstellationDef(
    id: 'corvus',
    name: 'Corvus',
    jaName: 'からす座',
    symbol: '\u{1F426}', // bird
    description: '春の南の空に見える小さな四辺形の星座。'
        'ギリシャ神話ではアポロンに仕えたカラスが、嘘をついた罰として'
        '空に上げられたとされる。4つの3等級の星が台形を作り、'
        '隣のコップ座・うみへび座と合わせて神話の一場面を構成する。',
    stars: [
      StarPosition(0.30, 0.30),
      StarPosition(0.60, 0.25),
      StarPosition(0.70, 0.50),
      StarPosition(0.35, 0.55),
      StarPosition(0.50, 0.70),
    ],
    connections: [
      StarConnection(0, 1),
      StarConnection(1, 2),
      StarConnection(2, 3),
      StarConnection(3, 0),
      StarConnection(3, 4),
    ],
  ),

  // コップ座 (Crater) - 杯の星座
  ConstellationDef(
    id: 'crater',
    name: 'Crater',
    jaName: 'コップ座',
    symbol: '\u{1F378}', // cocktail glass
    description: 'アポロンの聖杯を表す小さな星座。うみへび座の背中に乗るように位置する。'
        'プトレマイオスの48星座の一つで、古代ギリシャ時代から知られている。'
        '最も明るい星は4等級と暗いが、特徴的な杯の形は条件の良い場所で確認できる。',
    stars: [
      StarPosition(0.35, 0.25),
      StarPosition(0.65, 0.25),
      StarPosition(0.70, 0.45),
      StarPosition(0.30, 0.45),
      StarPosition(0.45, 0.60),
      StarPosition(0.55, 0.60),
    ],
    connections: [
      StarConnection(0, 1),
      StarConnection(1, 2),
      StarConnection(2, 5),
      StarConnection(0, 3),
      StarConnection(3, 4),
      StarConnection(4, 5),
    ],
  ),

  // や座 (Sagitta) - 最小の星座の一つ
  ConstellationDef(
    id: 'sagitta',
    name: 'Sagitta',
    jaName: 'や座',
    symbol: '\u{1F3F9}', // bow and arrow
    description: '全天で3番目に小さい星座。はくちょう座とわし座の間、天の川の中に位置する。'
        'ヘラクレスがわし座（プロメテウスの肝臓を食べる鷲）を射た矢とされる。'
        'プトレマイオスの48星座の一つで、小さいながらも矢の形がわかりやすい。',
    stars: [
      StarPosition(0.20, 0.45),
      StarPosition(0.45, 0.45),
      StarPosition(0.65, 0.45),
      StarPosition(0.80, 0.45),
      StarPosition(0.60, 0.30),
      StarPosition(0.60, 0.60),
    ],
    connections: [
      StarConnection(0, 1),
      StarConnection(1, 2),
      StarConnection(2, 3),
      StarConnection(2, 4),
      StarConnection(2, 5),
    ],
  ),

  // たて座 (Scutum) - 盾の星座
  ConstellationDef(
    id: 'scutum',
    name: 'Scutum',
    jaName: 'たて座',
    symbol: '\u{1F6E1}', // shield
    description: '1684年にポーランドの天文学者ヘヴェリウスが設定した比較的新しい星座。'
        'ポーランド王ヤン3世ソビエスキの盾を記念して名付けられた。'
        '天の川の濃い部分に位置し、散開星団M11（「野鴨星団」）は'
        '約3,000個の星からなる美しい天体として知られる。',
    stars: [
      StarPosition(0.40, 0.25),
      StarPosition(0.65, 0.30),
      StarPosition(0.70, 0.55),
      StarPosition(0.45, 0.65),
      StarPosition(0.30, 0.45),
    ],
    connections: [
      StarConnection(0, 1),
      StarConnection(1, 2),
      StarConnection(2, 3),
      StarConnection(3, 4),
      StarConnection(4, 0),
    ],
  ),

  // こぎつね座 (Vulpecula) - 小さなきつね
  ConstellationDef(
    id: 'vulpecula',
    name: 'Vulpecula',
    jaName: 'こぎつね座',
    symbol: '\u{1F98A}', // fox
    description: 'ヘヴェリウスが1687年に設定した星座。はくちょう座の南に位置する。'
        '亜鈴状星雲（M27）は最初に発見された惑星状星雲で、1764年にメシエが記録した。'
        'また、1967年にこの星座の方向で最初のパルサー（CP 1919）が発見され、'
        '天文学史上の重要な発見の場となった。',
    stars: [
      StarPosition(0.20, 0.40),
      StarPosition(0.35, 0.45),
      StarPosition(0.50, 0.40),
      StarPosition(0.65, 0.45),
      StarPosition(0.80, 0.42),
    ],
    connections: [
      StarConnection(0, 1),
      StarConnection(1, 2),
      StarConnection(2, 3),
      StarConnection(3, 4),
    ],
  ),

  // ほうおう座 (Phoenix) - 不死鳥
  ConstellationDef(
    id: 'phoenix',
    name: 'Phoenix',
    jaName: 'ほうおう座',
    symbol: '\u{1F525}', // fire
    description: '16世紀末にオランダの航海者が南天探検で設定した星座。'
        '伝説の不死鳥フェニックスを表す。α星アンカー（2.4等級）は'
        'アラビア語で「輝くもの」を意味する。日本からは秋から冬にかけて'
        '南の地平線近くに見えることがあるが、高度が低く観測は難しい。',
    stars: [
      StarPosition(0.50, 0.15), // 頭
      StarPosition(0.40, 0.30),
      StarPosition(0.60, 0.30),
      StarPosition(0.30, 0.50), // 左翼
      StarPosition(0.70, 0.50), // 右翼
      StarPosition(0.45, 0.65),
      StarPosition(0.55, 0.65),
    ],
    connections: [
      StarConnection(0, 1),
      StarConnection(0, 2),
      StarConnection(1, 3),
      StarConnection(2, 4),
      StarConnection(1, 5),
      StarConnection(2, 6),
    ],
  ),

  // とけい座 (Horologium) - 時計の星座
  ConstellationDef(
    id: 'horologium',
    name: 'Horologium',
    jaName: 'とけい座',
    symbol: '\u{1F570}', // clock
    description: 'フランスの天文学者ラカイユが1752年に南天で設定した星座。'
        '振り子時計（ホロロジウム）を表し、科学機器にちなむラカイユの星座の一つ。'
        '最も明るいα星でも3.9等級と暗い。2019年に大規模銀河団'
        '「ホロロジウム超銀河団」がこの方向で確認されている。',
    stars: [
      StarPosition(0.50, 0.15),
      StarPosition(0.55, 0.30),
      StarPosition(0.50, 0.45),
      StarPosition(0.45, 0.60),
      StarPosition(0.50, 0.80),
    ],
    connections: [
      StarConnection(0, 1),
      StarConnection(1, 2),
      StarConnection(2, 3),
      StarConnection(3, 4),
    ],
  ),

  // ろ座 (Fornax) - 化学炉の星座
  ConstellationDef(
    id: 'fornax',
    name: 'Fornax',
    jaName: 'ろ座',
    symbol: '\u{1F52C}', // microscope (closest)
    description: 'ラカイユが設定した星座で、化学実験用の炉を表す。'
        'ハッブル宇宙望遠鏡による「ハッブル・ウルトラ・ディープ・フィールド」は'
        'この星座の方向で撮影され、約130億年前の初期宇宙の銀河が写し出された。'
        'ろ座銀河団は約6,200万光年先にある比較的近い銀河団。',
    stars: [
      StarPosition(0.30, 0.30),
      StarPosition(0.50, 0.50),
      StarPosition(0.70, 0.30),
      StarPosition(0.40, 0.65),
      StarPosition(0.60, 0.65),
    ],
    connections: [
      StarConnection(0, 1),
      StarConnection(1, 2),
      StarConnection(1, 3),
      StarConnection(1, 4),
    ],
  ),

  // ちょうこくしつ座 (Sculptor) - 彫刻室
  ConstellationDef(
    id: 'sculptor',
    name: 'Sculptor',
    jaName: 'ちょうこくしつ座',
    symbol: '\u{1F3A8}', // palette
    description: 'ラカイユが設定した星座で、彫刻家のアトリエを表す。'
        '銀河系の南極（銀河面に対して垂直方向）がこの星座にあるため、'
        '銀河系の星やガスに邪魔されず遠方の銀河が観測しやすい。'
        'NGC 253（ちょうこくしつ座銀河）は南天で最も明るい渦巻銀河の一つ。',
    stars: [
      StarPosition(0.25, 0.35),
      StarPosition(0.40, 0.40),
      StarPosition(0.55, 0.35),
      StarPosition(0.70, 0.40),
      StarPosition(0.50, 0.55),
      StarPosition(0.35, 0.60),
    ],
    connections: [
      StarConnection(0, 1),
      StarConnection(1, 2),
      StarConnection(2, 3),
      StarConnection(2, 4),
      StarConnection(4, 5),
      StarConnection(5, 1),
    ],
  ),

  // レチクル座 (Reticulum) - 十字線の星座
  ConstellationDef(
    id: 'reticulum',
    name: 'Reticulum',
    jaName: 'レチクル座',
    symbol: '\u{1F52D}', // telescope
    description: 'ラカイユが設定した星座で、望遠鏡の接眼レンズにある十字線（レチクル）を表す。'
        '全天で4番目に小さい星座。大マゼラン雲の近くに位置し、'
        'ゼータ星系は太陽に似た連星系で、系外惑星探索の対象として注目されている。',
    stars: [
      StarPosition(0.35, 0.30),
      StarPosition(0.65, 0.30),
      StarPosition(0.65, 0.60),
      StarPosition(0.35, 0.60),
    ],
    connections: [
      StarConnection(0, 1),
      StarConnection(1, 2),
      StarConnection(2, 3),
      StarConnection(3, 0),
    ],
  ),

  // はと座 (Columba) - ノアの方舟のハト
  ConstellationDef(
    id: 'columba',
    name: 'Columba',
    jaName: 'はと座',
    symbol: '\u{1F54A}', // dove
    description: '16世紀にオランダの天文学者プランシウスが設定した星座。'
        'ノアの方舟から放たれたハトを表すとされる。'
        'おおいぬ座の南に位置し、α星ファクト（2.6等級）はアラビア語で「鳩」を意味する。'
        'μ星は秒速約100kmで高速移動する「暴走星」として知られる。',
    stars: [
      StarPosition(0.30, 0.35),
      StarPosition(0.45, 0.25),
      StarPosition(0.60, 0.30),
      StarPosition(0.70, 0.45),
      StarPosition(0.50, 0.55),
    ],
    connections: [
      StarConnection(0, 1),
      StarConnection(1, 2),
      StarConnection(2, 3),
      StarConnection(3, 4),
      StarConnection(4, 0),
    ],
  ),

  // きょしちょう座 (Tucana) - 南天のオオハシ
  ConstellationDef(
    id: 'tucana',
    name: 'Tucana',
    jaName: 'きょしちょう座',
    symbol: '\u{1F99C}', // parrot (closest)
    description: '16世紀末の南天探検で設定された星座で、南米のオオハシを表す。'
        '小マゼラン雲（SMC）がこの星座の領域にある。SMCは天の川銀河の伴銀河で、'
        '約20万光年先に位置する矮小不規則銀河。'
        'きょしちょう座47（NGC 104）は全天で2番目に明るい球状星団。',
    stars: [
      StarPosition(0.40, 0.25),
      StarPosition(0.55, 0.30),
      StarPosition(0.65, 0.40),
      StarPosition(0.55, 0.55),
      StarPosition(0.40, 0.55),
      StarPosition(0.30, 0.40),
    ],
    connections: [
      StarConnection(0, 1),
      StarConnection(1, 2),
      StarConnection(2, 3),
      StarConnection(3, 4),
      StarConnection(4, 5),
      StarConnection(5, 0),
    ],
  ),
];

/// インデックスに応じた星座を取得する.
ConstellationDef getConstellationForIndex(int index) {
  return constellations[index % constellations.length];
}
