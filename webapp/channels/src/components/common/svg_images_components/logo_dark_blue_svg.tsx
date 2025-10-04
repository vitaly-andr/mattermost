// Copyright (c) 2015-present Mattermost, Inc. All Rights Reserved.
// See LICENSE.txt for license information.

import React from 'react';
import styled from 'styled-components';

type Props = {
    width?: number;
    height?: number;
    className?: string;
}

const Svg = styled.svg.attrs({
    version: '1.1',
    xmlns: 'http://www.w3.org/2000/svg',
    xmlnsXlink: 'http://www.w3.org/1999/xlink',
})``;

export default (props: Props) => (
    <div style={{display: 'flex', alignItems: 'center', gap: '8px'}}>
        <div style={{display: 'flex', alignItems: 'center'}}>
            <img 
                src="/static/images/builder.svg" 
                alt="Bau-Portal" 
                style={{
                    height: '32px',
                    width: 'auto',
                    paddingLeft: '8px',
                    filter: 'brightness(0) invert(1)'
                }}
            />
        </div>
        <Svg
            className={props.className}
            width={props.width ? props.width.toString() : '200'}
            height={props.height ? props.height.toString() : '30'}
            viewBox='0 0 200 30'
            fill='none'
            xmlns='http://www.w3.org/2000/svg'
        >
            <text x="0" y="22" fontFamily="Arial, sans-serif" fontSize="24" fontWeight="600" fill="white">
                Bau-Portal.online
            </text>
        </Svg>
    </div>
);
