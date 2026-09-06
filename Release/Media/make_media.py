"""Export real Simulator footage. Requires Pillow and FFmpeg (FFMPEG env var)."""
from pathlib import Path
import os, subprocess
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
MEDIA = ROOT / 'Release/Media'
SOURCE = MEDIA / 'Source'
APP = ROOT / 'MorseApp/Tutorials'
OUT = MEDIA / 'AppStore'
WORK = MEDIA / '.work'
FF = os.environ.get('FFMPEG', 'ffmpeg')
for folder in [APP, OUT, WORK, MEDIA / 'GIFs']:
    folder.mkdir(parents=True, exist_ok=True)
FONT = '/System/Library/Fonts/Supplemental/Arial.ttf'
BOLD = '/System/Library/Fonts/Supplemental/Arial Bold.ttf'
ORANGE = '#FF9500'

def run(*args):
    subprocess.run([FF, '-hide_banner', '-loglevel', 'error', '-y', *map(str,args)], check=True)

def font(size, bold=False):
    return ImageFont.truetype(BOLD if bold else FONT, size)

def caption(name, title, detail, width=660):
    im = Image.new('RGB', (width, 180), '#111111')
    d = ImageDraw.Draw(im)
    d.text((28,24), title, font=font(30, True), fill=ORANGE)
    for i,line in enumerate(detail.split('\n')):
        d.text((28,76+i*34), line, font=font(25), fill='white')
    path = WORK / f'{name}-caption.png'; im.save(path)
    return path

def segment(name, source, start, end, title, detail):
    cap = caption(name,title,detail)
    dest = WORK / f'{name}.mp4'
    # Caption stays above the real screen, without obscuring controls.
    run('-i',SOURCE/source,'-i',cap,'-ss',start,'-t',end-start,
        '-filter_complex','[0:v]scale=660:1434,setsar=1,pad=660:1614:0:180:black[v];[v][1:v]overlay=0:0,fps=30[out]',
        '-map','[out]','-an','-c:v','libx264','-preset','fast','-crf','22','-pix_fmt','yuv420p',dest)
    return dest

def join(name, parts, dest):
    manifest = WORK / f'{name}.txt'
    manifest.write_text(''.join(f"file '{p}'\n" for p in parts))
    run('-f','concat','-safe','0','-i',manifest,'-c','copy','-movflags','+faststart',dest)

typing = 'typing-and-settings.mov'
guides = {
    'enable-keyboard': [
        ('enable-keyboard.mov',13,17,'1. Open General','iPhone Settings → General'),
        ('enable-keyboard.mov',19,23,'2. Open Keyboard','Choose Keyboard, then Keyboards.'),
        ('enable-keyboard.mov',25,29,'3. Add MorseBoard','Tap Add New Keyboard.'),
        ('enable-keyboard.mov',179,182.8,'4. Choose MorseBoard','Then use the globe key in a text field.'),
    ],
    'type-symbols': [
        (typing,8.5,15.5,'Tap out your message','Dot and dash keys insert Morse symbols.'),
    ],
    'alphabet': [
        (typing,35,40,'Choose Alphabet','Gear → Layout → Alphabet'),
        (typing,42,45,'Letters become Morse','Each letter gets a one-space separator.'),
        (typing,69.5,77.5,'Type HI MORSE','Space creates a wider word gap.'),
    ],
    'decode-letters': [
        (typing,118.5,122,'Turn Morse into letters','Three dots and a pause produce S.'),
        (typing,125,128.5,'Dash, dash, dash','Pause to finish O.'),
        (typing,132,136,'Finish with three dots','The keyboard writes SOS.'),
    ],
}
for name, shots in guides.items():
    parts = [segment(f'{name}-{i}',*shot) for i,shot in enumerate(shots)]
    dest = APP / f'{name}.mp4'
    join(name,parts,dest)
    run('-ss',1,'-i',dest,'-frames:v',1,APP/f'{name}.jpg')
    run('-i',dest,'-filter_complex',
        '[0:v]fps=8,scale=300:-1:flags=lanczos,split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=bayer',
        '-loop',0,MEDIA/'GIFs'/f'{name}.gif')
    print(f'Exported {name}', flush=True)

# Listing graphics contain only real app captures, framed with concise feature copy.
cards = [
    ('02-symbols.png','01-type-in-morse.png','Text in Morse.','Two big keys. Dots and dashes.',True),
    ('03-alphabet.png','02-alphabet.png','Letters in. Morse out.','A familiar alphabet keyboard.',True),
    ('04-letters.png','03-translate.png','Tap. Pause. Translate.','Turn Morse sequences into letters.',True),
    ('06-single-key.png','04-single-key.png','One key. Your rhythm.','Tap for a dot. Hold for a dash.',True),
    ('05-settings.png','05-settings.png','Make it yours.','Three layouts. Dot styles. Adjustable timing.',True),
]
for src,dest,title,subtitle,crop in cards:
    canvas = Image.new('RGB',(1320,2868),'#0B0B0D'); d=ImageDraw.Draw(canvas)
    d.ellipse((86,104,126,144),fill=ORANGE); d.rounded_rectangle((154,104,250,144),radius=5,fill=ORANGE)
    d.text((280,99),'MorseBoard',font=font(44,True),fill='white')
    d.text((86,244),title,font=font(78,True),fill='white')
    d.text((86,360),subtitle,font=font(43),fill='#C6C6CE')
    shot=Image.open(SOURCE/src).convert('RGB').crop((0,840,1320,2868))
    shot=shot.resize((1152,1770),Image.Resampling.LANCZOS)
    mask=Image.new('L',shot.size,0); ImageDraw.Draw(mask).rounded_rectangle((0,0,1151,1769),radius=56,fill=255)
    d.rounded_rectangle((76,540,1244,2326),radius=64,fill='#37373B')
    canvas.paste(shot,(84,548),mask)
    d.text((86,2460),'Your Morse Code keyboard.',font=font(52,True),fill=ORANGE)
    d.text((86,2550),'No Full Access required.',font=font(40),fill='#C6C6CE')
    canvas.save(OUT/dest)

# 25-second App Store preview, all footage from the running product.
parts=[]
for i,(start,end,title,detail) in enumerate([
    (8.5,15.5,'Text in Morse','Tap dots and dashes.'),
    (69.5,76.5,'Letters in. Morse out.','Type with the Alphabet layout.'),
    (132,138,'Translate Morse into letters','Pause to finish each letter.'),
    (172,177,'Make it yours','Choose the layout that suits you.'),
]):
    parts.append(segment(f'preview-{i}',typing,start,end,title,detail))
join('preview',parts,WORK/'preview.mp4')
run('-i',WORK/'preview.mp4','-f','lavfi','-i','anullsrc=r=48000:cl=stereo',
    '-vf','scale=784:1920,pad=886:1920:51:0:color=0x111111,setsar=1',
    '-r',30,'-c:v','libx264','-profile:v','high','-level:v','4.0','-b:v','10M',
    '-pix_fmt','yuv420p','-c:a','aac','-b:a','256k','-t',25,'-movflags','+faststart',OUT/'morseboard-preview.mp4')
run('-ss',5,'-i',OUT/'morseboard-preview.mp4','-frames:v',1,OUT/'preview-poster.jpg')
print('Listing screenshots and preview exported.',flush=True)
