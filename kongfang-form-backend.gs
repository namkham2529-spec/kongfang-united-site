/************************************************************************
 *  KONGFANG UNITED — หลังบ้านรับใบสมัครนักกีฬา (Google Apps Script)
 *  เก็บข้อมูลลง Google Sheet + รูปลง Google Drive อัตโนมัติ
 *  ------------------------------------------------------------------
 *  วิธีใช้: ดูไฟล์  "ตั้งค่า-Google-Sheet-หลังบ้าน.md"
 ************************************************************************/

// ============ ตั้งค่า (แก้ 3 บรรทัดนี้) ============
var SHEET_ID        = 'ใส่_SHEET_ID_ตรงนี้';   // จาก URL ของ Google Sheet
var DRIVE_FOLDER_ID = 'ใส่_FOLDER_ID_ตรงนี้';  // โฟลเดอร์ใน Drive สำหรับเก็บรูป
var NOTIFY_EMAIL    = 'namkham2529@gmail.com'; // เว้นว่าง '' = ไม่ต้องส่งเมลแจ้งเตือน
// =================================================

var SHEET_NAME = 'ใบสมัคร';
var HEADERS = [
  'เวลาบันทึก','เลขประจำตัว','ชื่อ-สกุล นักกีฬา','ชื่อเล่น','วันเดือนปีเกิด','เพศ',
  'รุ่นที่สมัคร','ตำแหน่งที่ถนัด','โรงเรียน','ระดับชั้น','ประสบการณ์ฟุตบอล',
  'โรคประจำตัว/แพ้ยา/แพ้อาหาร','ชื่อ-สกุล ผู้ปกครอง','ความสัมพันธ์','เบอร์โทรผู้ปกครอง',
  'Facebook/Line','ที่อยู่','ทราบข่าวจาก','หมายเหตุ','ลิงก์รูป','สถานะบัตร'
];

function doGet() {
  return _json({ ok: true, msg: 'Kongfang form backend is running' });
}

function doPost(e) {
  var lock = LockService.getScriptLock();
  try { lock.waitLock(30000); } catch (x) {}
  try {
    var p = (e && e.parameter) ? e.parameter : {};

    // กันบอท (honeypot)
    if (p._honey) return _json({ ok: true, skipped: true });

    var ss = SpreadsheetApp.openById(SHEET_ID);
    var sh = ss.getSheetByName(SHEET_NAME);
    if (!sh) sh = ss.insertSheet(SHEET_NAME);
    if (sh.getLastRow() === 0) {
      sh.appendRow(HEADERS);
      sh.getRange(1, 1, 1, HEADERS.length).setFontWeight('bold')
        .setBackground('#123B7A').setFontColor('#ffffff');
      sh.setFrozenRows(1);
    }

    var seq = sh.getLastRow();                 // แถวหัว = 1 → คนแรก seq = 1
    var pid = 'KFU-' + _pad(seq, 4);

    // ---- รูป → Drive ----
    var photoUrl = '';
    if (p.photo_base64) {
      var folder = DRIVE_FOLDER_ID && DRIVE_FOLDER_ID.indexOf('ใส่_') !== 0
        ? DriveApp.getFolderById(DRIVE_FOLDER_ID) : DriveApp.getRootFolder();
      var ct  = p.photo_type || 'image/jpeg';
      var ext = (ct.split('/')[1] || 'jpg').replace('jpeg', 'jpg');
      var nm  = (pid + '_' + (p['ชื่อ-สกุล นักกีฬา'] || 'นักกีฬา'))
                  .replace(/[\\\/:*?"<>|]+/g, '').replace(/\s+/g, '_');
      var blob = Utilities.newBlob(Utilities.base64Decode(p.photo_base64), ct, nm + '.' + ext);
      var file = folder.createFile(blob);
      try { file.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW); } catch (x) {}
      photoUrl = 'https://drive.google.com/uc?id=' + file.getId();
    }

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

    // ---- เมลแจ้งเตือน (สำรอง) ----
    if (NOTIFY_EMAIL && NOTIFY_EMAIL.indexOf('@') > 0) {
      var body = '';
      for (var i = 0; i < HEADERS.length; i++) body += HEADERS[i] + ' : ' + row[i] + '\n';
      body += '\nรูป: ' + (photoUrl || '(ไม่มี)') + '\nชีต: ' + ss.getUrl();
      try {
        MailApp.sendEmail({
          to: NOTIFY_EMAIL,
          subject: 'ใบสมัครนักกีฬาใหม่ · ' + (p['ชื่อ-สกุล นักกีฬา'] || '') +
                   '  (รุ่น ' + (p['รุ่นที่สมัคร'] || '-') + ')',
          body: body
        });
      } catch (x) {}
    }

    return _json({ ok: true, id: pid, photo: photoUrl });
  } catch (err) {
    return _json({ ok: false, error: String(err) });
  } finally {
    try { lock.releaseLock(); } catch (x) {}
  }
}

function _pad(n, w) { n = String(n); while (n.length < w) n = '0' + n; return n; }
function _json(o) {
  return ContentService.createTextOutput(JSON.stringify(o))
    .setMimeType(ContentService.MimeType.JSON);
}

/* ทดสอบเขียนแถวได้จากในเอดิเตอร์: กด Run ที่ฟังก์ชันนี้ */
function ทดสอบเขียนแถว() {
  doPost({ parameter: {
    'ชื่อ-สกุล นักกีฬา': 'ทดสอบ ระบบชีต',
    'รุ่นที่สมัคร': 'U12', 'เพศ': 'ชาย',
    'เบอร์โทรผู้ปกครอง': '000', 'ที่อยู่': 'ทดสอบ'
  }});
}
