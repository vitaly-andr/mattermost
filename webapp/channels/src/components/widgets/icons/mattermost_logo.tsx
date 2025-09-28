// Copyright (c) 2015-present Mattermost, Inc. All Rights Reserved.
// See LICENSE.txt for license information.

import React from 'react';
import type {CSSProperties} from 'react';
import {useIntl} from 'react-intl';

export default function MattermostLogo(props: React.HTMLAttributes<HTMLSpanElement>) {
    const {formatMessage} = useIntl();
    return (
        <span {...props}>
            <svg
                version='1.1'
                x='0px'
                y='0px'
                viewBox='0 0 500 500'
                enableBackground='new 0 0 500 500'
                role='img'
                aria-label={formatMessage({id: 'generic_icons.bauportal', defaultMessage: 'Bau-Portal Logo'})}
            >
                <g>
                    <g>
                        <path
                            style={style}
                            d='M250,50 C350,50 430,130 430,230 C430,330 350,410 250,410 C150,410 70,330 70,230 C70,130 150,50 250,50 Z'
                            fill='#0066CC'
                        />
                    </g>
                    <g>
                        <rect x='180' y='150' width='140' height='20' rx='10' fill='white'/>
                        <rect x='180' y='190' width='100' height='20' rx='10' fill='white'/>
                        <rect x='180' y='230' width='120' height='20' rx='10' fill='white'/>
                        <rect x='180' y='270' width='80' height='20' rx='10' fill='white'/>
                        <polygon points='150,120 180,150 150,180' fill='white'/>
                        <text x='200' y='340' font-family='Arial, sans-serif' font-size='24' font-weight='bold' fill='white'>BAU</text>
                    </g>
                </g>
            </svg>
        </span>
    );
}

const style: CSSProperties = {
    fillRule: 'evenodd',
    clipRule: 'evenodd',
};
