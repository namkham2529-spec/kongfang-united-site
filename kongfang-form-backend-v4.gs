/************************************************************************
 *  KONGFANG UNITED — หลังบ้านรับฟอร์มจากเว็บ (Google Apps Script) v4
 *  รับ 2 ฟอร์ม: ใบสมัครนักกีฬา + คำสั่งซื้อชุดแข่ง (แนบสลิป + ตรวจสลิปอัตโนมัติ)
 *  เก็บลง Google Sheet (คนละชีต) + รูป/สลิป ลง Google Drive อัตโนมัติ
 *  ------------------------------------------------------------------
 *  วิธีอัปเดต (URL เดิมไม่เปลี่ยน):
 *   1) ก๊อปทั้งไฟล์นี้ วางทับโค้ดเดิมใน Apps Script
 *   2) กรอกค่าตั้งค่าด้านล่าง (SLIP_* เว้นว่างไว้ก่อนได้ = ข้ามการตรวจสลิป)
 *   3) Deploy > Manage deployments > กดดินสอแก้ > Version: New version > Deploy
 ************************************************************************/

// ============ ตั้งค่า ============
var SHEET_ID        = '1HDoPo4Hh0eulvm6glpIbh9ncF4FTVRa7P1FTMu9jI3k';
var DRIVE_FOLDER_ID = '';
var NOTIFY_EMAIL    = 'namkham2529@gmail.com';

// ตรวจสลิปอัตโนมัติ (SlipOK) — สมัครที่ slipok.com แล้วเอา API Key + Branch ID มาใส่
// เว้นว่าง 2 บรรทัดนี้ = ระบบยังทำงานปกติ แค่ไม่ตรวจสลิป (เก็บรูปสลิปอย่างเดียว)
var SLIP_API_KEY    = '';
var SLIP_BRANCH_ID  = '';
// =================================

var REG_SHEET   = 'ใบสมัคร';
var ORDER_SHEET = 'สั่งเสื้อ';

var REG_HEADERS = [
  'เวลาบันทึก','เลขประจำตัว','ชื่อ-สกุล นักกีฬา','ชื่อเล่น','วันเดือนปีเกิด','เพศ',
  'รุ่นที่สมัคร','ตำแหน่งที่ถนัด','โรงเรียน','ระดับชั้น','ประสบการณ์ฟุตบอล',
  'โรคประจำตัว/แพ้ยา/แพ้อาหาร','ชื่อ-สกุล ผู้ปกครอง','ความสัมพันธ์','เบอร์โทรผู้ปกครอง',
  'Facebook/Line','ที่อยู่','ทราบข่าวจาก','หมายเหตุ','ลิงก์รูป','สถานะบัตร'
];
var ORDER_HEADERS = [
  'เวลาบันทึก','เลขที่ออเดอร์','ชื่อ-สกุล ผู้สั่ง','เบอร์โทร','ชื่อพิมพ์หลังเสื้อ','เบอร์เสื้อ',
  'ขนาด','จำนวน (ชุด)','ยอดค่าเสื้อ (350/ชุด)','ที่อยู่จัดส่ง','สถานะ','ลิงก์สลิป',
  'ผลตรวจสลิป','ชื่อผู้โอน','ยอดตามสลิป','เลขอ้างอิงสลิป','วันเวลาโอน','หมายเหตุ'
];

function doGet() {
  return _json({ ok: true, msg: 'Kongfang form backend is running' });
}

function doPost(e) {
  var lock = LockService.getScriptLock();
  try { lock.waitLock(30000); } catch (x) {}
  try {
    var p = (e && e.parameter) ? e.parameter : {};
    if (p._honey) return _json({ ok: true, skipped: true });
    var ss = SpreadsheetApp.openById(SHEET_ID);
    if (p.form_type === 'order') return _handleOrder(ss, p);
    return _handleReg(ss, p);
  } catch (err) {
    return _json({ ok: false, error: String(err) });
  } finally {
    try { lock.releaseLock(); } catch (x) {}
  }
}

function _handleReg(ss, p) {
  var sh = _sheet(ss, REG_SHEET, REG_HEADERS);
  var seq = sh.getLastRow();
  var pid = 'KFU-' + _pad(seq, 4);

  var photoUrl = '';
  if (p.photo_base64) photoUrl = _saveImg(p.photo_base64, p.photo_type, pid + '_' + (p['ชื่อ-สกุล นักกีฬา'] || 'นักกีฬา'));

  var row = [
    new Date(), pid,
    p['ชื่อ-สกุล นักกีฬา'] || '', p['ชื่อเล่น'] || '', p['วันเดือนปีเกิด'] || '', p['เพศ'] || '',
    p['รุ่นที่สมัคร'] || '', p['ตำแหน่งที่ถนัด'] || '', p['โรงเรียน'] || '', p['ระดับชั้น'] || '',
    p['ประสบการณ์ฟุตบอล'] || '', p['โรคประจำตัว-แพ้ยา-แพ้อาหาร'] || '',
    p['ชื่อ-สกุล ผู้ปกครอง'] || '', p['ความสัมพันธ์'] || '', p['เบอร์โทรผู้ปกครอง'] || '',
    p['Facebook หรือ Line'] || '', p['ที่อยู่'] || '', p['ทราบข่าวจาก'] || '', p['หมายเหตุ'] || '',
    photoUrl, 'ยัง'
  ];
  sh.appendRow(row);
  _notify('ใบสมัครนักกีฬาใหม่ · ' + (p['ชื่อ-สกุล นักกีฬา'] || '') +
          '  (รุ่น ' + (p['รุ่นที่สมัคร'] || '-') + ')', REG_HEADERS, row, ss, photoUrl);
  return _json({ ok: true, id: pid, photo: photoUrl });
}

function _handleOrder(ss, p) {
  var sh = _sheet(ss, ORDER_SHEET, ORDER_HEADERS);
  var seq = sh.getLastRow();
  var oid = 'ORD-' + _pad(seq, 4);
  var qty = parseInt(p.qty, 10) || 1;

  var slipUrl = '';
  var v = { status: '', sender: '', amount: '', ref: '', datetime: '' };
  if (p.slip_base64) {
    slipUrl = _saveImg(p.slip_base64, p.slip_type, oid + '_slip_' + (p.customer_name || ''));
    v = _verifySlip(p.slip_base64, p.slip_type);
  } else {
    v.status = 'ไม่ได้แนบสลิป';
  }

  var row = [
    new Date(), oid,
    p.customer_name || '', p.phone || '', p.shirt_name || '', p.shirt_number || '',
    p.size || '', qty, qty * 350, (p.address || p.note || ''), 'ใหม่', slipUrl,
    v.status, v.sender, v.amount, v.ref, v.datetime, (p.address ? (p.note || '') : '')
  ];
  sh.appendRow(row);
  _notify('คำสั่งซื้อชุดแข่งใหม่ · ' + (p.customer_name || '') +
          '  (' + (p.size || '-') + ' x ' + qty + ')  [สลิป: ' + (v.status || '-') + ']',
          ORDER_HEADERS, row, ss, slipUrl);
  return _json({ ok: true, id: oid, slip: slipUrl, slip_check: v.status, slip_amount: v.amount, slip_ref: v.ref });
}

/* ---- ตรวจสลิปด้วย SlipOK ----
 * คืนค่า { status, sender, amount, ref, datetime }
 * status: "ยังไม่ตั้งค่า" | "ผ่าน" | "สลิปซ้ำ" | "ตรวจไม่ผ่าน: <เหตุผล>"
 */
function _verifySlip(b64, ctype) {
  var out = { status: 'รอตรวจ', sender: '', amount: '', ref: '', datetime: '' };
  if (!SLIP_API_KEY || !SLIP_BRANCH_ID) { out.status = 'ยังไม่ตั้งค่า SlipOK'; return out; }
  try {
    var ct   = ctype || 'image/jpeg';
    var ext  = (ct.split('/')[1] || 'jpg').replace('jpeg', 'jpg');
    var blob = Utilities.newBlob(Utilities.base64Decode(b64), ct, 'slip.' + ext);
    var res  = UrlFetchApp.fetch('https://api.slipok.com/api/line/apikey/' + SLIP_BRANCH_ID, {
      method: 'post',
      headers: { 'x-authorization': SLIP_API_KEY },
      payload: { files: blob, log: 'true' },
      muteHttpExceptions: true
    });
    var body = JSON.parse(res.getContentText() || '{}');
    if (body && body.success && body.data) {
      var d = body.data;
      out.status   = 'ผ่าน';
      out.sender   = (d.sender && (d.sender.displayName || d.sender.name)) || '';
      out.amount   = d.amount || '';
      out.ref      = d.transRef || '';
      out.datetime = _slipDateTime(d);
    } else {
      var code = body ? body.code : 0;
      var msg  = (body && body.message) || 'ตรวจไม่สำเร็จ';
      out.status = (code === 1010 || code === 1013) ? 'สลิปซ้ำ' : ('ตรวจไม่ผ่าน: ' + msg);
    }
  } catch (err) {
    out.status = 'ตรวจไม่ผ่าน: ' + String(err);
  }
  return out;
}
function _slipDateTime(d) {
  if (d.transTimestamp) return d.transTimestamp;
  var dt = d.transDate || '', tm = d.transTime || '';
  if (dt.length === 8) dt = dt.slice(6, 8) + '/' + dt.slice(4, 6) + '/' + dt.slice(0, 4);
  return (dt + ' ' + tm).trim();
}

function _saveImg(b64, ctype, nameBase) {
  var folder = (DRIVE_FOLDER_ID && DRIVE_FOLDER_ID.indexOf('ใส่_') !== 0)
    ? DriveApp.getFolderById(DRIVE_FOLDER_ID) : DriveApp.getRootFolder();
  var ct  = ctype || 'image/jpeg';
  var ext = (ct.split('/')[1] || 'jpg').replace('jpeg', 'jpg');
  var nm  = String(nameBase || 'file').replace(/[\\\/:*?"<>|]+/g, '').replace(/\s+/g, '_');
  var blob = Utilities.newBlob(Utilities.base64Decode(b64), ct, nm + '.' + ext);
  var file = folder.createFile(blob);
  try { file.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW); } catch (x) {}
  return 'https://drive.google.com/uc?id=' + file.getId();
}

function _sheet(ss, name, headers) {
  var sh = ss.getSheetByName(name);
  if (!sh) sh = ss.insertSheet(name);
  if (sh.getLastRow() === 0) {
    sh.appendRow(headers);
    sh.getRange(1, 1, 1, headers.length).setFontWeight('bold')
      .setBackground('#123B7A').setFontColor('#ffffff');
    sh.setFrozenRows(1);
  }
  return sh;
}
function _notify(subject, headers, row, ss, photoUrl) {
  if (!NOTIFY_EMAIL || NOTIFY_EMAIL.indexOf('@') < 1) return;
  var body = '';
  for (var i = 0; i < headers.length; i++) body += headers[i] + ' : ' + row[i] + '\n';
  if (photoUrl) body += '\nรูป/สลิป: ' + photoUrl;
  body += '\nชีต: ' + ss.getUrl();
  try { MailApp.sendEmail({ to: NOTIFY_EMAIL, subject: subject, body: body }); } catch (x) {}
}
function _pad(n, w) { n = String(n); while (n.length < w) n = '0' + n; return n; }
function _json(o) {
  return ContentService.createTextOutput(JSON.stringify(o)).setMimeType(ContentService.MimeType.JSON);
}

function ทดสอบใบสมัคร() {
  doPost({ parameter: { 'ชื่อ-สกุล นักกีฬา': 'ทดสอบ ระบบชีต', 'รุ่นที่สมัคร': 'U12',
    'เพศ': 'ชาย', 'เบอร์โทรผู้ปกครอง': '000', 'ที่อยู่': 'ทดสอบ' } });
}
function ทดสอบสั่งเสื้อ() {
  doPost({ parameter: { form_type: 'order', customer_name: 'ทดสอบ สั่งเสื้อ',
    phone: '000', size: 'M', qty: '2', shirt_name: 'KONGFANG', shirt_number: '10',
    address: '1 หมู่ 1 ต.สองชั้น อ.กระสัง จ.บุรีรัมย์ 31160', note: 'ทดสอบ' } });
}
