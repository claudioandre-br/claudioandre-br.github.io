---
Title: Main title
Description: Main.
---

## Welcome to Pico

Congratulations, you have successfully installed [Pico](http://picocms.org/).
%meta.description% <!-- replaced by the above Description meta header -->

## Creating Content

Palestras

- Apresentação sobre OpenBRR
- Apresentação sobre o conceito de software livre
- Apresentação sobre SELinux no Android
- Apresentação sobre o autenticação no MapView do Android
- Apresentação sobre o auditoria de senhas em hardware paralelo

Artigos

Congresso. Portugal: CIAWI, 2008.
- Avaliação de um produto de software livre: produto de automação de testes

Congresso. Guarulhos: SEMCITEC, 2012.
- O Uso de Processamento Paralelo Como Ferramenta de Segurança

Congressos. Alfenas: UNIFAL, 2014.
- Os riscos de segurança inerentes ao uso dos modernos equipamentos médicos informatizados
- Efeitos clínicos da segurança da informação em dispositivos médicos implantados
- Um jogo eletrônico que ensina microbiologia para crianças
- Uma janela de oportunidades na computação de alto desempenho

Congresso. Pouso Alegre: IFSULDEMINAS, 2014.
- Estratégias de otimização de código em OpenCL
- Arquivos Fonte
- Arquivo fonte para controlador PIC16F84A

Outros Textos
- Texto sobre OpenCL no John the Ripper (com crypt SHA-512)
- John the Ripper via Ubuntu on Windows

<table style="width: 100%; max-width: 40em;">
    <thead>
        <tr>
            <th style="width: 50%;">Physical Location</th>
            <th style="width: 50%;">URL</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td>content/index.md</td>
            <td><a href="%base_url%">/</a></td>
        </tr>
        <tr>
            <td>content/sub.md</td>
            <td><del>?sub</del> (not accessible, see below)</td>
        </tr>
        <tr>
            <td>content/sub/index.md</td>
            <td><a href="%base_url%?sub">?sub</a> (same as above)</td>
        </tr>
        <tr>
            <td>content/sub/page.md</td>
            <td><a href="%base_url%?sub/page">?sub/page</a></td>
        </tr>
        <tr>
            <td>content/a/very/long/url.md</td>
            <td>
              <a href="%base_url%?a/very/long/url">?a/very/long/url</a>
              (doesn't exist)
            </td>
        </tr>
    </tbody>
</table>

[NginxConfig]: http://picocms.org/in-depth/nginx/
