---
title: Response Templates (EN/ES)
---

# Response Templates (English / Spanish)

Templates keep replies consistent, friendly and complete. **Personalize every one**: use the person's name, mention their specific issue and remove what does not apply. Placeholders are in `[brackets]`.

!!! tip "Tone guidelines"
    - **Acknowledge** the impact ("I understand you can't access your email, and I know that's frustrating before a deadline").
    - **Be specific** about what happens next and when.
    - **Plain language**, no jargon. Say "your email app" instead of "the OST cache".
    - **One action per step** when asking the user to do something.
    - Never blame the user. Say "let's try" instead of "you should have".

## 1. Ticket acknowledgement

=== "English"

    ```text
    Hi [First name],

    Thanks for contacting the IT Service Desk. We've logged your request as
    [Ticket ID] with priority [P3 – Medium].

    A technician will get back to you by [time/date]. In the meantime, this
    article may help: [KB link].

    If anything changes or it becomes more urgent, just reply to this email.

    Kind regards,
    [Your name]
    Acme Corp IT Service Desk
    ```

=== "Español"

    ```text
    Hola [Nombre]:

    Gracias por contactar a la Mesa de Ayuda de IT. Registramos tu solicitud
    con el número [ID de ticket] y prioridad [P3 – Media].

    Un técnico te va a responder antes de [hora/fecha]. Mientras tanto, este
    artículo te puede servir: [link a la KB].

    Si algo cambia o se vuelve más urgente, respondé este correo.

    Saludos,
    [Tu nombre]
    Mesa de Ayuda de IT – Acme Corp
    ```

## 2. Request for more information

=== "English"

    ```text
    Hi [First name],

    I'm looking into [short description of the issue]. To move forward, could
    you please send me:

    1. A screenshot of the error message
    2. The approximate time it last happened
    3. Whether you are in the office or working remotely

    I've set the ticket to "Waiting for your reply". I'll follow up on
    [date] if I don't hear back.

    Thanks,
    [Your name]
    ```

=== "Español"

    ```text
    Hola [Nombre]:

    Estoy revisando [breve descripción del problema]. Para avanzar, ¿me podrías
    enviar lo siguiente?

    1. Una captura de pantalla del mensaje de error
    2. La hora aproximada en que pasó por última vez
    3. Si estás trabajando en la oficina o de forma remota

    Dejé el ticket en estado "Esperando tu respuesta". Si no tengo novedades,
    te vuelvo a escribir el [fecha].

    Gracias,
    [Tu nombre]
    ```

## 3. Escalation notice

=== "English"

    ```text
    Hi [First name],

    Quick update on [Ticket ID]: I've escalated your case to our [Network]
    team, who have the tools to investigate [the VPN gateway] further.
    I've shared everything we tried together, so you won't need to repeat it.

    You'll hear from them or from me by [time/date]. Your workaround for now:
    [use Outlook on the web at https://outlook.office.com].

    Sorry for the inconvenience, and thank you for your patience.
    [Your name]
    ```

=== "Español"

    ```text
    Hola [Nombre]:

    Te cuento cómo sigue el [ID de ticket]: escalé tu caso al equipo de
    [Redes], que tiene las herramientas para revisar [el gateway de la VPN]
    más a fondo. Les pasé todo lo que probamos juntos, así que no vas a tener
    que repetirlo.

    Vas a tener novedades de ellos o mías antes de [hora/fecha]. Mientras
    tanto, podés [usar Outlook en la web: https://outlook.office.com].

    Perdón por las molestias y gracias por la paciencia.
    [Tu nombre]
    ```

## 4. Resolution and confirmation

=== "English"

    ```text
    Hi [First name],

    Good news: [your email is syncing again]. The cause was [a corrupted local
    cache file], which I rebuilt.

    If it happens again, these steps can help: [KB link].

    I'll mark the ticket as resolved. If anything isn't working as expected,
    just reply within 3 business days and it will reopen automatically.

    Have a great day,
    [Your name]
    ```

=== "Español"

    ```text
    Hola [Nombre]:

    ¡Buenas noticias! [Tu correo ya se está sincronizando de nuevo]. La causa
    era [un archivo de caché local dañado], que regeneré.

    Si vuelve a pasar, estos pasos te pueden ayudar: [link a la KB].

    Voy a marcar el ticket como resuelto. Si algo no funciona como esperabas,
    respondé dentro de los próximos 3 días hábiles y se vuelve a abrir
    automáticamente.

    ¡Que tengas un buen día!
    [Tu nombre]
    ```

## 5. Major incident notice (P1)

=== "English"

    ```text
    Subject: [Investigating] Email delivery delays – [time]

    We are aware that some users are experiencing [delays sending and
    receiving email]. Our team is actively working on it with [Microsoft].

    Workaround: [Teams chat is not affected; use it for urgent communication].
    You don't need to open a new ticket. Next update by [time].

    Acme Corp IT Service Desk
    ```

=== "Español"

    ```text
    Asunto: [En análisis] Demoras en el envío de correos – [hora]

    Sabemos que algunos usuarios tienen [demoras para enviar y recibir
    correos]. Nuestro equipo ya está trabajando en el problema junto con
    [Microsoft].

    Alternativa: [el chat de Teams funciona con normalidad; usalo para lo
    urgente]. No hace falta abrir un ticket nuevo. Próxima actualización:
    [hora].

    Mesa de Ayuda de IT – Acme Corp
    ```

## 6. Declining a request politely

=== "English"

    ```text
    Hi [First name],

    Thanks for your request to install [application]. Unfortunately, it isn't
    on our approved software list because [it stores company data on
    unmanaged cloud services].

    A supported alternative that covers the same need is [OneDrive / approved
    tool], available in Company Portal. If you need [application] for a
    specific business reason, your manager can request a security review
    here: [link].

    Happy to help you get set up with the alternative.
    [Your name]
    ```

=== "Español"

    ```text
    Hola [Nombre]:

    Gracias por tu pedido de instalación de [aplicación]. Lamentablemente no
    está en la lista de software aprobado porque [guarda datos de la empresa
    en servicios en la nube no administrados].

    Una alternativa soportada que cubre la misma necesidad es [OneDrive /
    herramienta aprobada], disponible en Company Portal. Si necesitás
    [aplicación] por un motivo de negocio puntual, tu responsable puede
    pedir una revisión de seguridad acá: [link].

    Si querés, te ayudo a configurar la alternativa.
    [Tu nombre]
    ```
